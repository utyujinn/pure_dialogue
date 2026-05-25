import asyncio
import io
import json
import logging
import os
import subprocess
import sys

import httpx
import numpy as np
import soundfile as sf
from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.responses import FileResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
from faster_whisper import WhisperModel

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
log = logging.getLogger(__name__)

try:
    from huggingface_hub import hf_hub_download
    from irodori_tts.inference_runtime import InferenceRuntime, RuntimeKey, SamplingRequest
    _HAS_TTS = True
except ImportError:
    _HAS_TTS = False
    log.warning("irodori_tts not found — IrodoriTTS disabled.")

OLLAMA_URL = os.environ.get("OLLAMA_URL", "")
if not OLLAMA_URL:
    print("ERROR: OLLAMA_URL が未設定です。例: export OLLAMA_URL='http://100.x.x.x:11434'", file=sys.stderr)
    sys.exit(1)

OLLAMA_MODEL_DEFAULT = os.environ.get("OLLAMA_MODEL", "qwen2.5:7b")
VOICEVOX_URL        = os.environ.get("VOICEVOX_URL", "")
VOICEVOX_SPEAKER    = int(os.environ.get("VOICEVOX_SPEAKER", "46"))
DEVICE              = os.environ.get("DEVICE", "cpu")

SYSTEM_PROMPT = (
    "あなたは親切なAIアシスタントです。"
    "ユーザーと自然な日本語で会話してください。"
    "返答は短く簡潔にまとめてください。"
)

app = FastAPI()

log.info("Whisper モデルをロード中...")
whisper = WhisperModel("small", device=DEVICE, compute_type="int8")
log.info("Whisper ロード完了")

TTS_REPO = "Aratako/Irodori-TTS-500M-v3"
tts: "InferenceRuntime | None" = None
if _HAS_TTS:
    log.info("IrodoriTTS ロード中: %s", TTS_REPO)
    _ckpt_path = hf_hub_download(repo_id=TTS_REPO, filename="model.safetensors")
    tts = InferenceRuntime.from_key(RuntimeKey(checkpoint=_ckpt_path, model_device=DEVICE))
    log.info("IrodoriTTS ロード完了")

_ref_wav_path = os.path.abspath("assets/model.wav")
REF_WAV = _ref_wav_path if os.path.exists(_ref_wav_path) else None
if REF_WAV:
    log.info("参照音声: %s", REF_WAV)
else:
    log.warning("assets/model.wav が見つかりません — no_ref モードで合成します")

app.mount("/assets", StaticFiles(directory="assets"), name="assets")


@app.get("/")
def root():
    return FileResponse("frontend/index.html")


@app.get("/models")
async def get_models():
    try:
        async with httpx.AsyncClient(timeout=5) as client:
            r = await client.get(f"{OLLAMA_URL}/api/tags")
            r.raise_for_status()
            names = [m["name"] for m in r.json().get("models", [])]
            return JSONResponse(names)
    except Exception as e:
        log.warning("Ollamaモデル一覧取得失敗: %s", e)
        return JSONResponse([])


@app.get("/speakers")
async def get_speakers():
    if not VOICEVOX_URL:
        return JSONResponse([])
    try:
        async with httpx.AsyncClient(timeout=5) as client:
            r = await client.get(f"{VOICEVOX_URL}/speakers")
            r.raise_for_status()
            # Flatten to [{id, name}] for easy consumption
            result = []
            for spk in r.json():
                for style in spk.get("styles", []):
                    result.append({"id": style["id"], "name": f"{spk['name']} ({style['name']})"})
            return JSONResponse(result)
    except Exception as e:
        log.warning("VoiceVox話者一覧取得失敗: %s", e)
        return JSONResponse([])


# ── STT ──────────────────────────────────────────────────────────

def decode_webm(webm_bytes: bytes) -> np.ndarray:
    proc = subprocess.run(
        ["ffmpeg", "-hide_banner", "-loglevel", "error",
         "-i", "pipe:0", "-f", "s16le", "-ar", "16000", "-ac", "1", "pipe:1"],
        input=webm_bytes, capture_output=True,
    )
    if proc.returncode != 0 or not proc.stdout:
        log.warning("ffmpeg decode failed: %s", proc.stderr.decode(errors="replace"))
        return np.zeros(0, dtype=np.float32)
    return np.frombuffer(proc.stdout, dtype=np.int16).astype(np.float32) / 32768.0


def run_whisper(pcm: np.ndarray) -> str:
    if pcm.size < 1600:
        return ""
    segments, _ = whisper.transcribe(pcm, language="ja", vad_filter=True)
    return "".join(seg.text for seg in segments).strip()


# ── TTS ──────────────────────────────────────────────────────────

def run_tts_irodori(text: str) -> bytes:
    req = SamplingRequest(text=text, ref_wav=REF_WAV) if REF_WAV else SamplingRequest(text=text, no_ref=True)
    result = tts.synthesize(req)
    audio = result.audio.squeeze().cpu().numpy()
    buf = io.BytesIO()
    sf.write(buf, audio, result.sample_rate, format="WAV", subtype="PCM_16")
    return buf.getvalue()


async def run_tts_voicevox(text: str, speaker: int) -> bytes:
    async with httpx.AsyncClient(timeout=30) as client:
        r = await client.post(
            f"{VOICEVOX_URL}/audio_query",
            params={"text": text, "speaker": speaker},
        )
        r.raise_for_status()
        r2 = await client.post(
            f"{VOICEVOX_URL}/synthesis",
            params={"speaker": speaker},
            json=r.json(),
        )
        r2.raise_for_status()
        return r2.content


async def synthesize(text: str, engine: str, loop: asyncio.AbstractEventLoop, speaker: int) -> bytes:
    if engine == "voicevox" and VOICEVOX_URL:
        return await run_tts_voicevox(text, speaker)
    if tts:
        return await loop.run_in_executor(None, run_tts_irodori, text)
    return b""


# ── LLM + TTS パイプライン ────────────────────────────────────────

SENTENCE_ENDS = frozenset("。！？\n.!?")


async def stream_llm_and_tts(
    ws: WebSocket,
    loop: asyncio.AbstractEventLoop,
    history: list,
    engine: str,
    model: str,
    speaker: int,
):
    sentence_buf = ""
    full_response = ""

    async with httpx.AsyncClient(timeout=60) as client:
        async with client.stream("POST", f"{OLLAMA_URL}/api/chat", json={
            "model": model,
            "messages": history,
            "stream": True,
        }) as resp:
            if resp.status_code != 200:
                body = await resp.aread()
                err = body.decode(errors="replace")
                log.error("Ollama %d: %s", resp.status_code, err)
                await ws.send_json({"type": "llm_text", "text": f"[Ollamaエラー {resp.status_code}: {err}]"})
                await ws.send_json({"type": "done"})
                return

            async for line in resp.aiter_lines():
                if not line:
                    continue
                chunk = json.loads(line)
                token = chunk.get("message", {}).get("content", "")
                if not token:
                    continue

                sentence_buf += token
                full_response += token
                await ws.send_json({"type": "llm_text", "text": token})

                if any(c in token for c in SENTENCE_ENDS) and sentence_buf.strip():
                    wav = await synthesize(sentence_buf.strip(), engine, loop, speaker)
                    if wav:
                        await ws.send_bytes(wav)
                    sentence_buf = ""

    if sentence_buf.strip():
        wav = await synthesize(sentence_buf.strip(), engine, loop, speaker)
        if wav:
            await ws.send_bytes(wav)

    await ws.send_json({"type": "done"})
    if full_response:
        history.append({"role": "assistant", "content": full_response})


# ── WebSocket ─────────────────────────────────────────────────────

@app.websocket("/ws")
async def websocket_handler(ws: WebSocket):
    await ws.accept()
    history   = [{"role": "system", "content": SYSTEM_PROMPT}]
    audio_buf = bytearray()
    loop      = asyncio.get_event_loop()
    tts_engine      = "irodori"
    ollama_model    = OLLAMA_MODEL_DEFAULT
    voicevox_speaker = VOICEVOX_SPEAKER

    try:
        while True:
            msg = await ws.receive()
            if msg["type"] == "websocket.disconnect":
                break

            if msg.get("bytes"):
                audio_buf.extend(msg["bytes"])
                continue

            data = json.loads(msg.get("text", "{}"))

            if data.get("type") == "set_tts":
                tts_engine = data.get("engine", "irodori")
                log.info("TTS engine → %s", tts_engine)
                continue

            if data.get("type") == "set_model":
                ollama_model = data.get("model", OLLAMA_MODEL_DEFAULT)
                log.info("Ollama model → %s", ollama_model)
                continue

            if data.get("type") == "set_speaker":
                voicevox_speaker = int(data.get("speaker", VOICEVOX_SPEAKER))
                log.info("VoiceVox speaker → %d", voicevox_speaker)
                continue

            if data.get("type") != "end_speech":
                continue

            if not audio_buf:
                await ws.send_json({"type": "done"})
                continue

            log.info("end_speech: %d bytes", len(audio_buf))
            try:
                pcm = await loop.run_in_executor(None, decode_webm, bytes(audio_buf))
                audio_buf.clear()
                log.info("PCM: %d samples (%.2fs)", pcm.size, pcm.size / 16000)

                transcript = await loop.run_in_executor(None, run_whisper, pcm)
                log.info("transcript: %r", transcript)

                if not transcript:
                    await ws.send_json({"type": "done"})
                    continue

                await ws.send_json({"type": "transcript", "text": transcript})
                history.append({"role": "user", "content": transcript})
                await stream_llm_and_tts(ws, loop, history, tts_engine, ollama_model, voicevox_speaker)

            except Exception as e:
                log.exception("pipeline error: %s", e)
                await ws.send_json({"type": "done"})

    except WebSocketDisconnect:
        pass
