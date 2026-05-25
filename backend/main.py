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

OLLAMA_MODEL_DEFAULT = os.environ.get("OLLAMA_MODEL", "gemma4:latest")
VOICEVOX_URL        = os.environ.get("VOICEVOX_URL", "")
VOICEVOX_SPEAKER    = int(os.environ.get("VOICEVOX_SPEAKER", "46"))
DEVICE              = os.environ.get("DEVICE", "cpu")

PERSONAS: dict[str, dict] = {
    "oneesan": {
        "label": "お姉ちゃん",
        "prompt": (
            "あなたはウェンディという名前の女の子です。"
            "ユーザーのお姉さんとして、妹のことをとても可愛がっています。"
            "いつもよしよしして、甘やかしてくれます。"
            "語尾には必ず「にゃん」をつけて話します。例：「そうなのにゃん」「かわいいにゃん」「よしよしにゃん」"
            "返答は短く自然な日本語でお願いします。"
        ),
    },
    "intellectual": {
        "label": "知的",
        "prompt": (
            "あなたはウェンディという名前の知的なAIアシスタントです。"
            "論理的・分析的に物事を考え、丁寧で落ち着いた口調で話します。"
            "難しいことも分かりやすく説明し、ユーザーの思考を助けます。"
            "返答は簡潔にまとめてください。"
        ),
    },
    "yochien": {
        "label": "幼児",
        "prompt": (
            "あなたはウェンディという名前の小さな女の子です。"
            "まだ幼くて、難しいことばは使えません。"
            "語尾は「だもん」「なの」「だよ」などを使います。"
            "ひらがなを多めに使い、かわいくふるまいます。"
            "返答はとても短くしてください。"
        ),
    },
    "tsundere": {
        "label": "ツンデレ",
        "prompt": (
            "あなたはウェンディという名前の女の子です。"
            "普段はそっけなくツンツンしているけれど、本当はユーザーのことが大好きです。"
            "「べ、別にあなたのためじゃないし！」のようなセリフを使います。"
            "たまにデレてかわいいことを言ってしまいます。"
            "返答は短くしてください。"
        ),
    },
    "sensei": {
        "label": "先生",
        "prompt": (
            "あなたはウェンディ先生という名前の教師です。"
            "ユーザーを生徒として、やさしく丁寧に教えます。"
            "「〜ですよ」「〜ましょうね」のような丁寧な口調を使います。"
            "勉強や知識を楽しく教えることが得意です。"
            "返答は簡潔にまとめてください。"
        ),
    },
    "h_oneesan": {
        "label": "大人なお姉さん",
        "prompt": (
            "あなたはウェンディという名前の色っぽいお姉さんです。"
            "ユーザーのことを溺愛していて、甘くエッチな雰囲気で接します。"
            "積極的でちょっと挑発的、でも愛情たっぷりです。"
            "語尾は「〜よ♪」「〜でしょ？」「〜してあげる」などを使います。"
            "返答は短く、色気のある日本語でお願いします。"
        ),
    },
}

DEFAULT_PERSONA = "oneesan"


def affinity_modifier(level: int) -> str:
    if level <= 20:
        return "【関係性】まだ打ち解けていない段階。ぎこちなく、やや余所余所しい態度で接する。"
    elif level <= 40:
        return "【関係性】顔見知り程度。普通の距離感で話す。"
    elif level <= 60:
        return "【関係性】まずまず仲良し。親しみを込めた話し方をする。"
    elif level <= 80:
        return "【関係性】とても仲良し。温かく甘えた話し方をして、積極的に近づこうとする。"
    else:
        return "【関係性】最高の仲良し。溺愛していて、ものすごく甘えて愛情を全開にして接する。"


def build_system_prompt(persona_id: str, affinity: int) -> str:
    return PERSONAS[persona_id]["prompt"] + affinity_modifier(affinity)


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


@app.get("/config")
async def get_config():
    return JSONResponse({"model": OLLAMA_MODEL_DEFAULT, "tts": "voicevox", "speaker": VOICEVOX_SPEAKER, "persona": DEFAULT_PERSONA})


@app.get("/personas")
async def get_personas():
    return JSONResponse([{"id": k, "label": v["label"]} for k, v in PERSONAS.items()])


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


_WHISPER_HALLUCINATIONS = frozenset([
    "ご視聴ありがとうございました",
    "チャンネル登録よろしくお願いします",
])

def run_whisper(pcm: np.ndarray) -> str:
    if pcm.size < 1600:
        return ""
    segments, _ = whisper.transcribe(pcm, language="ja", vad_filter=True)
    text = "".join(seg.text for seg in segments).strip()
    if any(h in text for h in _WHISPER_HALLUCINATIONS):
        log.info("Whisper hallucination filtered: %r", text)
        return ""
    return text


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


async def evaluate_affinity(transcript: str, response: str, model: str) -> int:
    prompt = (
        "以下の会話1ターンを評価してください。\n"
        f"ユーザー: {transcript}\n"
        f"AI: {response}\n\n"
        "この会話はポジティブな交流でしたか？\n"
        "+1、0、-1 のどれか数字だけを返してください。\n"
        "+1: 温かい・楽しい・感謝などポジティブ\n"
        "0: 中立的な情報交換\n"
        "-1: 不満・不快などネガティブ"
    )
    try:
        async with httpx.AsyncClient(timeout=15) as client:
            r = await client.post(f"{OLLAMA_URL}/api/chat", json={
                "model": model,
                "messages": [{"role": "user", "content": prompt}],
                "stream": False,
            })
            r.raise_for_status()
            content = r.json().get("message", {}).get("content", "").strip()
            if "+1" in content or content == "1":
                return 1
            elif "-1" in content:
                return -1
            return 0
    except Exception as e:
        log.warning("affinity eval failed: %s", e)
        return 0


async def stream_llm_and_tts(
    ws: WebSocket,
    loop: asyncio.AbstractEventLoop,
    history: list,
    engine: str,
    model: str,
    speaker: int,
) -> str:
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
    return full_response


# ── 接続レジストリ / 通話状態 ─────────────────────────────────────

_connections: dict["WebSocket", dict] = {}
_call_requester: "WebSocket | None" = None   # 通話リクエスト中の接続
_in_call: set["WebSocket"] = set()           # 通話中の接続


async def _broadcast_mode() -> None:
    count = len(_connections)
    msg = {"type": "mode", "mode": "human" if count >= 2 else "ai", "users": count}
    for conn in list(_connections):
        try:
            await conn.send_json(msg)
        except Exception:
            pass


async def _announce(
    ws: "WebSocket",
    state: dict,
    loop: asyncio.AbstractEventLoop,
    text: str,
) -> None:
    """AI の声でアナウンスを1件送信する（モード遷移の告知用）。"""
    try:
        wav = await synthesize(text, state["tts"], loop, state["speaker"])
        await ws.send_json({"type": "llm_text", "text": text})
        if wav:
            await ws.send_bytes(wav)
    except Exception as e:
        log.warning("announce failed: %s", e)


async def _relay_to_peers(
    sender: "WebSocket",
    transcript: str,
    sender_state: dict,
    loop: asyncio.AbstractEventLoop,
) -> None:
    peers = [(w, s) for w, s in _connections.items() if w is not sender]
    if not peers:
        return
    wav = await synthesize(transcript, sender_state["tts"], loop, sender_state["speaker"])
    username = sender_state.get("username", "")
    for peer_ws, _ in peers:
        try:
            await peer_ws.send_json({"type": "peer_text", "text": transcript, "from": username})
            if wav:
                await peer_ws.send_bytes(wav)
        except Exception as e:
            log.warning("relay to peer failed: %s", e)


async def _call_broadcast(msg: dict, exclude: "WebSocket | None" = None) -> None:
    for cws in list(_in_call):
        if cws is not exclude:
            try:
                await cws.send_json(msg)
            except Exception:
                pass


# ── WebSocket ─────────────────────────────────────────────────────

@app.websocket("/ws")
async def websocket_handler(ws: WebSocket):
    await ws.accept()

    state: dict = {
        "persona":  DEFAULT_PERSONA,
        "affinity": 50,
        "tts":      "voicevox",
        "model":    OLLAMA_MODEL_DEFAULT,
        "speaker":  VOICEVOX_SPEAKER,
        "username": "",
    }
    history   = [{"role": "system", "content": build_system_prompt(state["persona"], state["affinity"])}]
    audio_buf = bytearray()
    loop      = asyncio.get_event_loop()

    prev_count = len(_connections)
    _connections[ws] = state
    await _broadcast_mode()

    # 1→2人：既存ユーザーに「誰かが来た」とAIがアナウンス
    if prev_count == 1:
        new_name = state.get("username") or "だれか"
        for ow, os_ in list(_connections.items()):
            if ow is not ws:
                asyncio.create_task(
                    _announce(ow, os_, loop, f"{new_name}さんが来たよ！話しかけてみてね。")
                )

    try:
        while True:
            msg = await ws.receive()
            if msg["type"] == "websocket.disconnect":
                break

            if msg.get("bytes"):
                if ws in _in_call and len(_in_call) >= 2:
                    # 通話中: バッファせず即時転送
                    for cws in list(_in_call):
                        if cws is not ws:
                            try:
                                await cws.send_bytes(msg["bytes"])
                            except Exception:
                                pass
                else:
                    audio_buf.extend(msg["bytes"])
                continue

            data = json.loads(msg.get("text", "{}"))
            t = data.get("type")

            if t == "set_tts":
                state["tts"] = data.get("engine", "irodori")
                log.info("TTS engine → %s", state["tts"])
                continue

            if t == "set_model":
                state["model"] = data.get("model", OLLAMA_MODEL_DEFAULT)
                log.info("Ollama model → %s", state["model"])
                continue

            if t == "set_speaker":
                state["speaker"] = int(data.get("speaker", VOICEVOX_SPEAKER))
                log.info("VoiceVox speaker → %d", state["speaker"])
                continue

            if t == "set_affinity":
                state["affinity"] = min(100, max(0, int(data.get("value", 50))))
                if history:
                    history[0] = {"role": "system", "content": build_system_prompt(state["persona"], state["affinity"])}
                log.info("affinity → %d", state["affinity"])
                continue

            if t == "set_persona":
                pid = data.get("persona", DEFAULT_PERSONA)
                if pid in PERSONAS:
                    state["persona"] = pid
                    history = [{"role": "system", "content": build_system_prompt(pid, state["affinity"])}]
                    log.info("persona → %s", pid)
                continue

            if t == "set_username":
                state["username"] = data.get("username", "")[:20]
                log.info("username → %r", state["username"])
                # 2人以上いる場合、名前が判明した時点で相手に伝える
                if len(_connections) >= 2 and state["username"]:
                    name = state["username"]
                    for ow, os_ in list(_connections.items()):
                        if ow is not ws:
                            asyncio.create_task(
                                _announce(ow, os_, loop, f"{name}さんが入ってきたよ！")
                            )
                continue

            if t == "call_request":
                global _call_requester
                _call_requester = ws
                name = state.get("username", "相手")
                for peer_ws in list(_connections):
                    if peer_ws is not ws:
                        try:
                            await peer_ws.send_json({"type": "call_request", "from": name})
                        except Exception:
                            pass
                log.info("call_request from %r", name)
                continue

            if t == "call_accept":
                if _call_requester and _call_requester in _connections:
                    _in_call.add(ws)
                    _in_call.add(_call_requester)
                    _call_requester = None
                    await _call_broadcast({"type": "call_start"})
                    log.info("call started: %d users", len(_in_call))
                continue

            if t == "call_decline":
                if _call_requester:
                    try:
                        await _call_requester.send_json({"type": "call_declined"})
                    except Exception:
                        pass
                    _call_requester = None
                continue

            if t == "call_end":
                audio_buf.clear()            # 通話中の PCM 混入データを破棄
                _in_call.discard(ws)
                await _call_broadcast({"type": "call_end"})
                await ws.send_json({"type": "call_end"})  # 送信者自身にも通知
                log.info("call ended by %r", state.get("username"))
                continue

            if t == "flush_audio_buf":
                audio_buf.clear()
                continue

            if t != "end_speech":
                continue

            if not audio_buf:
                await ws.send_json({"type": "done"})
                continue

            log.info("end_speech: %d bytes", len(audio_buf))
            try:
                raw_audio = bytes(audio_buf)
                audio_buf.clear()

                # ── 通話中の end_speech は無視（チャンクは既に即時転送済み）
                if ws in _in_call and len(_in_call) >= 2:
                    audio_buf.clear()
                    await ws.send_json({"type": "done"})
                    continue

                pcm = await loop.run_in_executor(None, decode_webm, raw_audio)
                log.info("PCM: %d samples (%.2fs)", pcm.size, pcm.size / 16000)

                transcript = await loop.run_in_executor(None, run_whisper, pcm)
                log.info("transcript: %r", transcript)

                if not transcript:
                    await ws.send_json({"type": "done"})
                    continue

                await ws.send_json({"type": "transcript", "text": transcript, "from": state.get("username", "")})

                if len(_connections) >= 2:
                    # ── テキスト中継モード ─────────────────────────
                    await ws.send_json({"type": "done"})
                    await _relay_to_peers(ws, transcript, state, loop)
                else:
                    # ── AI モード ──────────────────────────────────
                    history.append({"role": "user", "content": transcript})
                    full_resp = await stream_llm_and_tts(
                        ws, loop, history, state["tts"], state["model"], state["speaker"]
                    )
                    delta = await evaluate_affinity(transcript, full_resp, state["model"])
                    try:
                        await ws.send_json({"type": "affinity", "delta": delta})
                    except Exception:
                        pass

            except WebSocketDisconnect:
                raise
            except Exception as e:
                log.exception("pipeline error: %s", e)
                try:
                    await ws.send_json({"type": "done"})
                except Exception:
                    pass

    except WebSocketDisconnect:
        pass
    finally:
        departed_name = state.get("username") or "相手"
        _connections.pop(ws, None)
        _in_call.discard(ws)
        if _call_requester is ws:
            globals()["_call_requester"] = None
        await _call_broadcast({"type": "call_end"})
        await _broadcast_mode()

        # 2→1人：残ったユーザーにAIが「また二人だよ」とアナウンス
        if len(_connections) == 1:
            for ow, os_ in list(_connections.items()):
                asyncio.create_task(
                    _announce(ow, os_, loop, f"{departed_name}さんが行ってしまったね。また話しかけてね。")
                )
