// ── カラーパレット ────────────────────────────────────────────────
#let bg      = rgb("#06071a")
#let bg2     = rgb("#0d1540")
#let accent  = rgb("#ff6699")
#let accent2 = rgb("#7f88ff")
#let fg      = rgb("#eeeeff")
#let muted   = rgb("#8899bb")
#let card    = rgb("#111a3a")

// ── ページ設定 ────────────────────────────────────────────────────
#set page(paper: "presentation-16-9", fill: bg, margin: 0pt)
#set text(
  font: ("Source Han Sans", "Noto Sans CJK JP"),
  fill: fg,
  size: 18pt,
)
#set par(leading: 0.65em, spacing: 0.9em)
#show raw: set text(font: ("UDEV Gothic", "Noto Sans Mono CJK JP"), size: 14pt)

// ── ユーティリティ ────────────────────────────────────────────────
#let badge(color, body) = box(
  fill: color.lighten(80%),
  inset: (x: 6pt, y: 2pt),
  radius: 4pt,
  text(fill: color.darken(25%), size: 0.68em, weight: "bold", body),
)

#let card-box(body) = block(
  fill: card,
  inset: 10pt,
  radius: 7pt,
  stroke: 0.5pt + muted.transparentize(50%),
  width: 100%,
  body,
)

#let dot(color) = text(fill: color, weight: "bold")[◆ ]

// 背景デコレーション
#let bg-deco() = {
  place(top + right,
    rect(width: 320pt, height: 320pt, radius: 50%,
      fill: gradient.radial(accent.transparentize(88%), bg.transparentize(100%))))
  place(bottom + left,
    rect(width: 240pt, height: 240pt, radius: 50%,
      fill: gradient.radial(accent2.transparentize(88%), bg.transparentize(100%))))
}

// 通常スライド
#let slide(header, body) = {
  bg-deco()
  place(top,
    rect(width: 100%, height: 48pt, fill: bg2,
      stroke: (bottom: 1pt + accent.transparentize(55%))))
  place(top + left,  dx: 28pt, dy: 10pt,
    text(size: 20pt, weight: "bold", fill: fg, header))
  place(top + right, dx: -20pt, dy: 14pt,
    text(size: 12pt, fill: muted, "AI VRM Chat"))
  block(width: 100%, height: 100%,
    inset: (top: 58pt, x: 28pt, bottom: 16pt),
    body)
  pagebreak()
}

// タイトルスライド
#let title-slide(title, subtitle: none, author: none, date: none) = {
  place(top + right,
    rect(width: 380pt, height: 380pt, radius: 50%,
      fill: gradient.radial(accent.transparentize(80%), bg.transparentize(100%))))
  place(bottom + left,
    rect(width: 280pt, height: 280pt, radius: 50%,
      fill: gradient.radial(accent2.transparentize(80%), bg.transparentize(100%))))
  place(left,
    rect(width: 5pt, height: 100%,
      fill: gradient.linear(accent, accent2, dir: ttb)))
  block(width: 100%, height: 100%,
    inset: (left: 68pt, right: 56pt, y: 56pt),
    align(horizon)[
      #text(fill: muted, size: 13pt, tracking: 3pt)[AI VRM CHAT]
      #v(8pt)
      #text(size: 34pt, weight: "black", fill: fg, title)
      #if subtitle != none { v(6pt); text(size: 18pt, fill: muted, subtitle) }
      #v(30pt)
      #line(length: 56pt, stroke: 1.5pt + accent)
      #v(12pt)
      #if author != none { text(size: 15pt, fill: fg, author); h(18pt) }
      #if date   != none { text(size: 13pt, fill: muted, date) }
    ])
  pagebreak()
}

// 終わりスライド
#let end-slide(title, body) = {
  place(top + right,
    rect(width: 380pt, height: 380pt, radius: 50%,
      fill: gradient.radial(accent.transparentize(80%), bg.transparentize(100%))))
  place(bottom + left,
    rect(width: 280pt, height: 280pt, radius: 50%,
      fill: gradient.radial(accent2.transparentize(80%), bg.transparentize(100%))))
  place(left,
    rect(width: 5pt, height: 100%,
      fill: gradient.linear(accent, accent2, dir: ttb)))
  block(width: 100%, height: 100%,
    inset: (left: 68pt, right: 56pt, y: 56pt),
    align(horizon)[
      #text(size: 36pt, weight: "black", title)
      #v(16pt)
      #body
    ])
}

// ════════════════════════════════════════════════════════════════
//  スライド本文
// ════════════════════════════════════════════════════════════════

// 1. タイトル
#title-slide(
  "ブラウザで動く\nAI キャラクター音声会話システム",
  subtitle: "VRM × Whisper × Ollama × VoiceVox",
  author: "石橋憲尚",
  date: "2026-05-25",
)

// 2. 何を作ったか
#slide("何を作ったか")[
  #grid(columns: (1fr, 1fr), gutter: 16pt)[
    #v(6pt)
    VRM 3D キャラクターとブラウザ上でリアルタイム音声会話できる Web アプリ

    #v(10pt)
    #card-box[
      #set text(size: 16pt)
      - *話しかける* → 自動で音声検知・認識
      - キャラが *口パク・瞬き* しながら返答
      - 会話を重ねると *親密度が上がり態度が変わる*
      - スマホ・PC どちらからでもアクセス可
    ]
    #v(10pt)
    #badge(accent2, "ビルド不要") #h(5pt)
    #badge(accent, "単一 HTML") #h(5pt)
    #badge(rgb("#44cc88"), "外部公開済み")
  ][
    #align(center)[
      #image("fig/screenshot.png", width: 100%)
      #text(fill: muted, size: 11pt)[アプリのスクリーンショット]
    ]
  ]
]

// 3. システム全体構成
#slide("システム全体構成")[
  #align(center + horizon)[
    #image("fig/architecture.png", width: 88%)
  ]
]

// 4. パイプラインの流れ
#slide("パイプラインの流れ")[
  #set text(size: 16pt)
  #let row(label, desc) = grid(
    columns: (110pt, 1fr),
    gutter: 0pt,
    block(inset: (bottom: 11pt), text(fill: accent2, weight: "bold", label)),
    block(inset: (bottom: 11pt), desc),
  )
  #row("◆ マイク",   "MediaRecorder で WebM/Opus を 200ms ごとに WebSocket 送信")
  #row("◆ STT",      "ffmpeg で PCM 変換 → faster-whisper (small, int8) で日本語認識")
  #row("◆ LLM",      "Ollama (gemma4) へストリーミング問い合わせ。文末が来た時点で TTS へ")
  #row("◆ TTS",      "VoiceVox Engine (Windows) または IrodoriTTS (WSL) が WAV を生成")
  #row("◆ 描画",     "Three.js + three-vrm でリップシンク・瞬きをフレームごとに制御")
  #row("◆ 親密度",   "応答後に別途 LLM を呼び出し +1/0/−1 を評価。Cookie で永続化")
]

// 5. 音声入力
#slide("音声入力：VAD と WebM の罠")[
  #grid(columns: (1fr, 1fr), gutter: 16pt)[
    #text(fill: accent, weight: "bold")[VAD（音声区間検出）]
    #v(4pt)
    #card-box[
      #set text(size: 16pt)
      AnalyserNode で RMS を毎フレーム計算
      - RMS > 0.012 → 発話開始
      - 1500ms 無音継続 → 発話終了
      - サーバーでも `vad_filter=True`
    ]
    #v(8pt)
    #text(fill: accent2, weight: "bold")[Whisper ハルシネーション対策]
    #card-box[
      #set text(size: 16pt)
      無音時に幻覚テキストを出力する既知問題
      「*ご視聴ありがとうございました*」など #linebreak()
      → フィルタリストで検知してスキップ
    ]
  ][
    #text(fill: accent, weight: "bold")[WebM EBML ヘッダー問題]
    #v(4pt)
    #card-box[
      #set text(size: 16pt)
      先頭チャンクにのみコンテナヘッダーが含まれる #linebreak()
      途中チャンクだけでは ffmpeg がデコードできない
    ]
    #v(8pt)
    #text(fill: accent2, weight: "bold")[解決策]
    #card-box[
      #set text(size: 16pt)
      `done` 受信後に `MediaRecorder` を再起動 #linebreak()
      → ヘッダーを再送させる

      ```
      stop() → end_speech
                  ← done
      start() → chunk（ヘッダー付き）
      ```
    ]
  ]
]

// 6. LLM連携
#slide("LLM 連携：ストリーミングとペルソナ")[
  #grid(columns: (1fr, 1fr), gutter: 16pt)[
    #card-box[
      #text(fill: accent, weight: "bold")[ストリーミング応答]
      #v(4pt)
      #set text(size: 16pt)
      Ollama の NDJSON をトークン単位で受信

      文末文字（`。！？` など）が来た時点で #linebreak()
      その文を即 TTS へ送る

      *→ 全文を待たずに音声が流れ始める*
    ]
    #v(8pt)
    #card-box[
      #text(fill: accent2, weight: "bold")[Tailscale + Cloudflare Tunnel]
      #v(4pt)
      #set text(size: 16pt)
      WSL ↔ Windows は Tailscale VPN で接続 #linebreak()
      Cloudflare Tunnel で `https://` 外部公開 #linebreak()
      スマホからも `wss://` で接続可能
    ]
  ][
    #card-box[
      #text(fill: accent, weight: "bold")[ペルソナシステム（6種）]
      #v(4pt)
      #set text(size: 15pt)
      - お姉ちゃん（語尾「にゃん」）
      - 知的 / 幼児 / ツンデレ / 先生 / 大人なお姉さん

      切り替え時は会話履歴をリセット #linebreak()
      → システムプロンプトを差し替え
    ]
    #v(8pt)
    #card-box[
      #text(fill: accent2, weight: "bold")[親密度の態度反映]
      #v(4pt)
      #set text(size: 15pt)
      システムプロンプトに関係性テキストを付加

      #text(fill: muted)[例：「最高の仲良し。溺愛していて #linebreak()
      ものすごく甘えて愛情を全開に…」]
    ]
  ]
]

// 7. 3Dフロントエンド
#slide("3D フロントエンド：VRM と詰まった点")[
  #grid(columns: (1fr, 1fr), gutter: 16pt)[
    #card-box[
      #text(fill: accent, weight: "bold")[Three.js + pixiv/three-vrm]
      #v(4pt)
      #set text(size: 15pt)
      CDN の ESM のみ → ビルドツール不要
      - リップシンク：RMS → `vrc.v_aa` モーフ
      - 瞬き：ランダムタイマーで `eye_blink`
      - 腕・体幹：正弦波でゆらゆら
      - キャンディゴースト：円軌道で周回
      - 泡パーティクル：InstancedMesh 90個
    ]
  ][
    #card-box[
      #text(fill: accent, weight: "bold")[詰まった点①：表情が動かない]
      #v(4pt)
      #set text(size: 15pt)
      VRM 1.0 だが表情定義が空 #linebreak()
      → `expressionManager` が null

      *解決*：`morphTargetDictionary` を traverse #linebreak()
      して `morphTargetInfluences` を直接操作
    ]
    #v(8pt)
    #card-box[
      #text(fill: accent2, weight: "bold")[詰まった点②：ゴーストが動かない]
      #v(4pt)
      #set text(size: 15pt)
      Spring bone が毎フレーム位置を上書き

      *解決*：VRM シーンから切り離して #linebreak()
      Three.js シーンに直接 add
    ]
  ]
]

// 8. 親密度システム
#slide("親密度システム")[
  #grid(columns: (1fr, 1fr), gutter: 16pt)[
    #v(4pt)
    会話のたびに LLM が評価して関係性が変化

    #v(8pt)
    #card-box[
      #text(fill: accent, weight: "bold")[評価フロー]
      #v(4pt)
      #set text(size: 16pt)
      + 応答完了後、同モデルに会話 1 ターンを評価
      + *+1 / 0 / −1* を WebSocket で返送
      + Cookie に保存（365 日）→ 次回接続時も継続
      + システムプロンプトに即時反映
    ]
    #v(8pt)
    #card-box[
      #text(fill: accent2, weight: "bold")[5 段階の態度変化]
      #v(4pt)
      #set text(size: 15pt)
      0〜20：余所余所しい　/　21〜60：普通〜親しみ #linebreak()
      61〜80：温かく甘える　/　81〜100：愛情全開
    ]
  ][
    #align(center + horizon)[
      #image("fig/affinity.png", width: 55%)
      #v(6pt)
      #text(fill: muted, size: 13pt)[
        画面左の縦型ゲージ #linebreak()
        上昇時にハートエフェクト
      ]
    ]
  ]
]

// 9. 工夫まとめ
#slide("工夫・苦労した点まとめ")[
  #set text(size: 15pt)
  #grid(columns: (1fr, 1fr), gutter: 12pt)[
    #card-box[
      #text(fill: accent, weight: "bold", size: 16pt)[音声ストリーミング再生]
      #v(4pt)
      LLM の文末トークンをトリガーに TTS → WAV → 即再生 #linebreak()
      全文を待たないため *体感速度が大幅に向上*
    ]
    #v(8pt)
    #card-box[
      #text(fill: accent, weight: "bold", size: 16pt)[WebM ヘッダー設計]
      #v(4pt)
      `processing` フラグで送信を制御 #linebreak()
      `done → start()` の順序を厳守 #linebreak()
      → ヘッダー欠損問題を完全解消
    ]
  ][
    #card-box[
      #text(fill: accent2, weight: "bold", size: 16pt)[AudioContext 制限対策]
      #v(4pt)
      Autoplay Policy で AudioContext が `suspended` #linebreak()
      クリック/タッチの capture フェーズで `resume()`
    ]
    #v(8pt)
    #card-box[
      #text(fill: accent2, weight: "bold", size: 16pt)[Whisper ハルシネーション]
      #v(4pt)
      無音時に決まり文句が出力される known issue #linebreak()
      頻出パターンをフィルタリストでブロック
    ]
  ]
]

// 10. まとめ
#slide("まとめと今後の展望")[
  #grid(columns: (1fr, 1fr), gutter: 16pt)[
    #card-box[
      #text(fill: accent, weight: "bold")[作ったもの]
      #v(4pt)
      #set text(size: 16pt)
      - ブラウザだけで動く音声会話 AI
      - ビルド不要・単一 HTML で完結
      - 外部 GPU マシンを Tailscale で活用
      - 親密度による動的な態度変化
      - スマホからも HTTPS でアクセス可
    ]
    #v(8pt)
    #card-box[
      #text(fill: accent, weight: "bold")[技術的な学び]
      #v(4pt)
      #set text(size: 16pt)
      音声・LLM・3D・WebSocket を組み合わせる際の *タイミング制御* の難しさ #linebreak()
      ブラウザの制約を一つずつ潰していく過程
    ]
  ][
    #card-box[
      #text(fill: accent2, weight: "bold")[今後やりたいこと]
      #v(4pt)
      #set text(size: 16pt)
      - 感情表現（表情・ジェスチャー）の LLM 連動
      - 長期記憶（会話サマリーの永続化）
      - より自然な間・相槌
      - マルチモーダル入力（カメラ・画像）
      - モデルのファインチューニング
    ]
  ]
]

// 11. 終わり
#end-slide("ご清聴ありがとうございました")[
  #v(14pt)
  #text(fill: muted, size: 17pt)[
    デモ：#link("https://talk.utyujin.com")[talk.utyujin.com]
  ]
]
