# AI VRM Chat

ブラウザ上で VRM 3D キャラクターとリアルタイム音声会話できる Web アプリ。  
マイクに話しかけると、キャラクターが口を動かしながら音声で返答する。

---

## システム構成

```
[ブラウザ]
  マイク (MediaRecorder/WebM)
      │  WebSocket バイナリ送信（音声チャンク）
      ▼
[WSL / NixOS — FastAPI サーバー :8000]
  ffmpeg  →  faster-whisper (STT, small int8)
      │  テキスト
      ▼
  Ollama API (ストリーミング)  ←─── HTTP / Tailscale ───→  [Windows — Ollama]
      │  トークン単位で受信、文末で TTS に渡す
      ▼
  IrodoriTTS  or  VoiceVox Engine
      │  WAV バイナリ
      ▼
[ブラウザ]
  AudioContext 再生 → リップシンク (RMS → aa 表情)
  Three.js / @pixiv/three-vrm でレンダリング
```

---

## ネットワーク・通信の詳細

### 概要

通信路は主に **WebSocket 1本** にまとまっている。ブラウザとサーバー間の全やりとりはここを流れる。

```
Browser ─── ws://host:8000/ws ─── FastAPI (WSL)
                                       │
                          HTTP ────────┤
                      (Tailscale VPN)  │
                          ┌────────────┘
                          ├─ Ollama   http://<tailscale-ip>:11434
                          └─ VoiceVox http://<tailscale-ip>:50021
```

---

### WebSocket プロトコル（`/ws`）

接続はブラウザ側から確立し、セッション中は切断しない。メッセージは **バイナリ** と **JSON テキスト** の 2 種類が混在する。

#### ブラウザ → サーバー

| フォーマット | 内容 |
|---|---|
| `bytes` | WebM/Opus 音声チャンク。`MediaRecorder` が 200ms ごとに `ondataavailable` で送出する。最初のチャンクに EBML ヘッダーが含まれる |
| `{"type":"end_speech"}` | 発話終了シグナル。サーバーはこれを受け取ったら蓄積した音声を処理する |
| `{"type":"set_tts","engine":"irodori"\|"voicevox"}` | TTS エンジン切り替え（接続単位で保持） |
| `{"type":"set_model","model":"qwen2.5:7b"}` | Ollama モデル切り替え |
| `{"type":"set_speaker","speaker":46}` | VoiceVox 話者 ID 変更 |

#### サーバー → ブラウザ

| フォーマット | 内容 |
|---|---|
| `bytes` | WAV（PCM 16bit）音声。文末ごとに送信される（ストリーミング再生） |
| `{"type":"transcript","text":"..."}` | Whisper の認識テキスト |
| `{"type":"llm_text","text":"..."}` | LLM のトークン（リアルタイム字幕用） |
| `{"type":"done"}` | 全処理完了。ブラウザ側はこれを受けてマイクを再起動する |

---

### 音声送信の仕組み（WebM ストリーミング）

WebM/Opus は EBML コンテナ形式で、**先頭チャンクにのみヘッダーが含まれる**。  
途中からのチャンクだけではデコードできないため、以下の制約がある：

- `MediaRecorder` は通話開始時に 1 回だけ `start()` し、**セッション中は停止しない**
- 発話中（`speaking=true`）は 200ms ごとに音声チャンクを WebSocket で送信
- 発話終了を検知したら `mediaRecorder.stop()` を呼ぶ
- `onstop` コールバック（最終チャンク送出後）で `end_speech` を送信
- サーバーから `done` を受け取ったら `mediaRecorder.start(200)` で再起動

この順序により、**再起動後の最初のチャンク（ヘッダー含む）が必ずサーバーに届く**。

```
start() ─ chunk ─ chunk ─ ... ─ stop()
                                   │ ondataavailable（最終）
                                   │ end_speech →→→ サーバー処理
                                   ▼
                               done ←←←
                                   │
                               start() ─ chunk（ヘッダー）─ ...
```

---

### VAD（音声区間検出）

サーバーサイドの VAD は使わず、**ブラウザ側のエネルギーベース VAD** で発話を検出する。

- `AudioWorklet` → `AnalyserNode` で RMS を毎フレーム計算
- RMS > `0.012`（閾値）が続いたら発話開始
- RMS < 閾値 が 1500ms 続いたら発話終了と判定

サーバー側では faster-whisper の `vad_filter=True` で無音区間をさらにフィルタする。

---

### Ollama との通信（ストリーミング）

Ollama は Windows 側で動作し、Tailscale VPN 経由でアクセスする。

```
POST http://<tailscale-ip>:11434/api/chat
{
  "model": "qwen2.5:7b",
  "messages": [...会話履歴...],
  "stream": true
}
```

レスポンスは NDJSON（改行区切り JSON）で返ってくる。サーバーは `httpx` の `aiter_lines()` でトークンを受信しながら：

1. `llm_text` として即時 WebSocket 送信（字幕表示）
2. `sentence_buf` に蓄積し、`。！？\n.!?` のいずれかが含まれた時点で TTS に渡す

これにより **最初の文末が来た時点で TTS 生成・音声送信が始まる**（全文生成を待たない）。

会話履歴はサーバーのメモリ上に `messages` リストとして保持し、毎回全履歴を Ollama に送る。

---

### TTS との通信

#### IrodoriTTS（ローカル）

WSL 上でモデルをロードし、同プロセス内で推論する。  
CPython の GIL があるため `loop.run_in_executor(None, run_tts_irodori, text)` でスレッドプールに投げ、asyncio イベントループをブロックしない。

- モデル: `Aratako/Irodori-TTS-500M-v3`（約 500M パラメータ）
- 参照音声: `assets/model.wav` があれば voice cloning、なければ `no_ref` モード
- 出力: WAV PCM 16bit → `soundfile` でシリアライズ → WebSocket バイナリ送信

#### VoiceVox（Windows 側）

VoiceVox Engine を `--host 0.0.0.0` で起動し、Tailscale 経由で HTTP 2 ステップで合成する。

```
POST /audio_query?text=...&speaker=46  → 音響クエリ JSON
POST /synthesis?speaker=46             → WAV バイナリ
```

---

## フロントエンド

単一の `frontend/index.html`（サーバーサイドビルド不要）。

### 3D レンダリング

| 技術 | 用途 |
|---|---|
| Three.js r163 | WebGL レンダラー |
| @pixiv/three-vrm 2.1.2 | VRM 読み込み・ヒューマノイドボーン・表情管理 |
| GLTFLoader + VRMLoaderPlugin | VRM ファイルのパース |

レンダラー設定：
- `SRGBColorSpace` + `ACESFilmicToneMapping`（MToon シェーダーを正しく表示するために必要）
- `HemisphereLight`（空色/海色）＋ `DirectionalLight`（太陽光）＋ フィルライト

アニメーション（毎フレーム `requestAnimationFrame`）：
- **上半身ゆらゆら**: spine/chest を正弦波で z 回転
- **腕の揺れ**: leftUpperArm / rightUpperArm を左右逆位相の正弦波で揺らす
- **瞬き**: 3〜7 秒ごとにランダムで `blink` / `blinkLeft` / `blinkRight` 表情をアニメート
- **リップシンク**: AudioContext の AnalyserNode で RMS を計算し `aa` 表情に lerp で追従
- **泡パーティクル**: `InstancedMesh` 90 個の半透明球が正弦波ドリフトしながら上昇

### カメラ操作

- **ドラッグ**: 球面座標でオービット（ヨー/ピッチ各 ±20°）
- **スクロール**: 半径（距離）変更（1.2〜7.0m）

### WebSocket クライアント

- バイナリ受信（WAV）→ `decodeAudioData` → `AudioBufferSourceNode` でキュー再生
- JSON 受信 → 字幕更新・状態管理・MediaRecorder 再起動

---

## 技術スタック

| レイヤー | 技術 |
|---|---|
| 実行環境 | WSL2 / NixOS (`nix-shell`) |
| パッケージ管理 | uv（Python 3.11 固定） |
| Web サーバー | FastAPI + Uvicorn（ASGI） |
| STT | faster-whisper（small, int8, CPU） |
| LLM | Ollama（Windows 側、Tailscale 経由） |
| TTS A | IrodoriTTS 500M v3（WSL ローカル） |
| TTS B | VoiceVox Engine（Windows 側、Tailscale 経由） |
| 音声変換 | ffmpeg（WebM/Opus → PCM 16kHz） |
| フロントエンド | Vanilla JS + Three.js + @pixiv/three-vrm（CDN ESM） |
| VPN | Tailscale（WSL ↔ Windows 間の通信） |

---

## セットアップ

### 1. Nix シェルに入る

```sh
nix-shell
```

### 2. IrodoriTTS をクローンして依存をインストール

```sh
git clone https://github.com/Aratako/Irodori-TTS
uv sync
```

モデルの事前ダウンロード（約 1GB、初回のみ）：

```sh
uv run python -c "
from huggingface_hub import snapshot_download
snapshot_download('Aratako/Irodori-TTS-500M-v3')
snapshot_download('Aratako/Semantic-DACVAE-Japanese-32dim')
"
```

### 3. VRM モデルと参照音声を配置

```sh
cp your_model.vrm assets/model.vrm
cp your_voice.wav assets/model.wav   # IrodoriTTS の voice cloning 用（省略可）
```

### 4. Windows 側の Ollama を起動（PowerShell）

```powershell
$env:OLLAMA_HOST = "0.0.0.0"
ollama serve
```

### 5. Windows 側の VoiceVox Engine を起動（PowerShell）

```powershell
& "C:\Program Files\VOICEVOX\vv-engine\run.exe" --host 0.0.0.0 --port 50021
```

### 6. サーバーを起動（WSL）

```sh
export OLLAMA_URL="http://<tailscale-ip>:11434"
export VOICEVOX_URL="http://<tailscale-ip>:50021"   # VoiceVox を使う場合
uv run uvicorn backend.main:app --host 0.0.0.0 --port 8000
```

ブラウザで `http://localhost:8000` を開く。

---

## 環境変数

| 変数 | デフォルト | 説明 |
|---|---|---|
| `OLLAMA_URL` | （必須） | Ollama の URL（例: `http://100.x.x.x:11434`） |
| `OLLAMA_MODEL` | `qwen2.5:7b` | デフォルト LLM モデル |
| `VOICEVOX_URL` | （空） | VoiceVox Engine の URL。未設定時は IrodoriTTS のみ |
| `VOICEVOX_SPEAKER` | `46`（小夜/SAYO） | VoiceVox デフォルト話者 ID |
| `DEVICE` | `cpu` | `cpu` または `cuda` |

---

## 使い方

1. ブラウザで開くと VRM キャラクターが表示される
2. マイクボタンをクリックしてマイクを起動
3. 話しかけると自動で発話を検知し、認識・応答・口パクが始まる
4. ⚙️ 設定パネルで TTS エンジン・話者・AI モデル・マイクを変更できる
5. 画面をドラッグでカメラ回転、スクロールでズーム
