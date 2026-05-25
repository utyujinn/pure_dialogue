# AI VRM Chat

ブラウザ上で VRM 3D キャラクターとリアルタイム音声会話できる Web アプリ。  
マイクに話しかけると、キャラクターが口を動かしながら音声で返答する。

---

## 機能

- **音声会話**: ページを開くと自動でマイクアクセスを要求。話しかけるだけで自動的に発話を検知・認識・応答する
- **リップシンク・瞬き**: 音声 RMS に基づいて口の形態素を制御。ランダムな瞬きアニメーション
- **ペルソナ切り替え**: 6 種類のキャラクター設定（お姉ちゃん・知的・幼児・ツンデレ・先生・大人なお姉さん）
- **親密度システム**: 会話のたびに LLM が +1 / 0 / -1 を判定。Cookie に保存され次回も引き継がれる。親密度に応じてキャラクターの態度が変化する
- **親密度ゲージ**: 画面左側に縦型ゲージで表示。上昇時にハートエフェクト
- **キャンディゴースト**: サブキャラクター (Wendy_Pet) がキャラクターの周りを円軌道で浮遊する
- **泡パーティクル**: 幻想的な半透明バブルが背景を漂う
- **カメラ操作**: ドラッグで上下左右 ±20° 回転、スクロールでズーム
- **TTS 切り替え**: VoiceVox（Windows 側）または IrodoriTTS（WSL ローカル）
- **HTTPS 対応**: Cloudflare Tunnel 経由で `wss://` に自動切り替え

---

## システム構成

```
[ブラウザ]
  マイク (MediaRecorder/WebM) — 自動で起動
      │  WebSocket バイナリ送信（音声チャンク）
      ▼
[WSL / NixOS — FastAPI サーバー :8000]
  ffmpeg  →  faster-whisper (STT, small int8)
      │  テキスト
      ▼
  Ollama API (ストリーミング)  ←─── HTTP / Tailscale ───→  [Windows — Ollama]
      │  トークン単位で受信、文末で TTS に渡す
      ▼
  VoiceVox Engine  or  IrodoriTTS
      │  WAV バイナリ
      ▼
[ブラウザ]
  AudioContext 再生 → リップシンク (RMS → aa 表情)
  Three.js / @pixiv/three-vrm でレンダリング

  ※ 応答後、別途 Ollama に会話評価を問い合わせて親密度 delta を算出
```

---

## ネットワーク・通信の詳細

### 概要

通信路は主に **WebSocket 1本** にまとまっている。

```
Browser ─── wss://talk.utyujin.com/ws ─── Cloudflare Tunnel ─── FastAPI (WSL :8000)
                                                                        │
                                                           HTTP (Tailscale VPN)
                                                                        │
                                                    ┌───────────────────┘
                                                    ├─ Ollama   http://<tailscale-ip>:11434
                                                    └─ VoiceVox http://<tailscale-ip>:50021
```

---

### WebSocket プロトコル（`/ws`）

#### ブラウザ → サーバー

| フォーマット | 内容 |
|---|---|
| `bytes` | WebM/Opus 音声チャンク。200ms ごとに送出。最初のチャンクに EBML ヘッダーが含まれる |
| `{"type":"end_speech"}` | 発話終了シグナル。蓄積音声の処理を開始する |
| `{"type":"set_tts","engine":"irodori"\|"voicevox"}` | TTS エンジン切り替え |
| `{"type":"set_model","model":"gemma4:latest"}` | Ollama モデル切り替え |
| `{"type":"set_speaker","speaker":46}` | VoiceVox 話者 ID 変更 |
| `{"type":"set_persona","persona":"oneesan"}` | ペルソナ切り替え（会話履歴リセット） |
| `{"type":"set_affinity","value":75}` | 現在の親密度を同期（接続時・変化時に送信） |

#### サーバー → ブラウザ

| フォーマット | 内容 |
|---|---|
| `bytes` | WAV（PCM 16bit）音声。文末ごとに送信（ストリーミング再生） |
| `{"type":"transcript","text":"..."}` | Whisper の認識テキスト |
| `{"type":"llm_text","text":"..."}` | LLM のトークン（リアルタイム字幕用） |
| `{"type":"done"}` | 全処理完了。ブラウザ側はこれを受けてマイクを再起動する |
| `{"type":"affinity","delta":1}` | 今回の会話の親密度変化量（+1 / 0 / -1） |

---

### 音声送信の仕組み（WebM ストリーミング）

WebM/Opus は先頭チャンクにのみヘッダーが含まれるため、以下の順序を厳守する：

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

- `AnalyserNode` で RMS を毎フレーム計算
- RMS > `0.012` で発話開始
- RMS < 閾値 が 1500ms 続いたら発話終了
- サーバー側では faster-whisper の `vad_filter=True` で無音をフィルタ

---

### 親密度評価

メインの LLM 応答完了後、同じ Ollama モデルに対して会話 1 ターン分を評価させる。  
返答（`+1` / `0` / `-1`）を `affinity` メッセージでブラウザに送信し、Cookie に保存する。  
親密度は 5 段階の関係性テキストとしてシステムプロンプトに付加され、次ターンの応答態度に反映される。

| 親密度 | 関係性 |
|---|---|
| 0〜20 | 打ち解けていない・余所余所しい |
| 21〜40 | 顔見知り程度・普通の距離感 |
| 41〜60 | まずまず仲良し |
| 61〜80 | とても仲良し・甘えた話し方 |
| 81〜100 | 最高の仲良し・愛情全開 |

---

### ペルソナ

| ID | ラベル | 特徴 |
|---|---|---|
| `oneesan` | お姉ちゃん | 語尾「にゃん」、溺愛してくれるお姉さん（デフォルト） |
| `intellectual` | 知的 | 論理的・丁寧・簡潔 |
| `yochien` | 幼児 | ひらがな多め、「だもん」「なの」 |
| `tsundere` | ツンデレ | そっけないが本当は大好き |
| `sensei` | 先生 | 丁寧に教えてくれる教師 |
| `h_oneesan` | 大人なお姉さん | 色気のある大人のお姉さん |

---

## フロントエンド

単一の `frontend/index.html`（ビルド不要、CDN ESM）。

### 3D レンダリング

| 技術 | 用途 |
|---|---|
| Three.js r163 | WebGL レンダラー |
| @pixiv/three-vrm 2.1.2 | VRM 読み込み・ヒューマノイドボーン |
| GLTFLoader + VRMLoaderPlugin | VRM ファイルのパース |

- `SRGBColorSpace` + `ACESFilmicToneMapping`（MToon シェーダー対応）
- `HemisphereLight` + `DirectionalLight` + フィルライト

アニメーション：
- **上半身ゆらゆら**: spine / chest を正弦波で z 回転
- **腕の揺れ**: 左右逆位相の正弦波
- **瞬き**: 3〜7 秒ごとにランダムで eye_blink 表情をアニメート（morphTargetInfluences 直接制御）
- **リップシンク**: AnalyserNode の RMS を aa 表情に lerp で追従
- **キャンディゴースト**: Wendy_Pet ノードを VRM シーンから切り離して独立管理。elapsed * 0.7 rad/s で周回
- **泡パーティクル**: InstancedMesh 90 個の半透明球が正弦波ドリフトで上昇

---

## 技術スタック

| レイヤー | 技術 |
|---|---|
| 実行環境 | WSL2 / NixOS |
| パッケージ管理 | uv |
| Web サーバー | FastAPI + Uvicorn（ASGI） |
| STT | faster-whisper（small, int8, CPU） |
| LLM | Ollama（Windows 側、Tailscale 経由）デフォルト: `gemma4:latest` |
| TTS A | VoiceVox Engine（Windows 側）デフォルト: 小夜/SAYO（ID 46） |
| TTS B | IrodoriTTS 500M v3（WSL ローカル） |
| 音声変換 | ffmpeg（WebM/Opus → PCM 16kHz） |
| フロントエンド | Vanilla JS + Three.js + @pixiv/three-vrm（CDN ESM） |
| VPN | Tailscale（WSL ↔ Windows 間の通信） |
| 公開 | Cloudflare Tunnel（`talk.utyujin.com`） |

---

## セットアップ

### 1. `.env` を作成

```sh
cat > .env <<EOF
OLLAMA_URL=http://<tailscale-ip>:11434
OLLAMA_MODEL=gemma4:latest
VOICEVOX_URL=http://<tailscale-ip>:50021
VOICEVOX_SPEAKER=46
DEVICE=cpu
EOF
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

VoiceVox のみ使う場合はスキップ可。

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

`VOICEVOX.exe` は `--host` オプションを受け付けないため `vv-engine\run.exe` を使う。

### 6. サーバーを起動（WSL）

```sh
uv run --env-file .env uvicorn backend.main:app --host 0.0.0.0 --port 8000
```

ローカルアクセス: `http://localhost:8000`  
外部アクセス: `https://talk.utyujin.com`（Cloudflare Tunnel 経由）

---

## 環境変数

| 変数 | デフォルト | 説明 |
|---|---|---|
| `OLLAMA_URL` | **必須** | Ollama の URL（例: `http://100.x.x.x:11434`） |
| `OLLAMA_MODEL` | `gemma4:latest` | デフォルト LLM モデル |
| `VOICEVOX_URL` | （空） | VoiceVox Engine の URL。未設定時は IrodoriTTS のみ |
| `VOICEVOX_SPEAKER` | `46`（小夜/SAYO） | VoiceVox デフォルト話者 ID |
| `DEVICE` | `cpu` | `cpu` または `cuda` |

---

## 使い方

1. ブラウザで開くと VRM キャラクターが表示され、自動でマイクアクセスを要求する
2. 許可するとすぐに音声認識が始まる。話しかけるだけで自動検知・応答する
3. ⚙️ ボタンで設定パネルを開き、ペルソナ・TTS・話者・AI モデル・マイクを変更できる
4. 画面左の縦型ゲージが親密度を表示。会話を重ねると上昇し、キャラクターの態度が変化する
5. 画面をドラッグでカメラ回転、スクロールでズーム
