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
    text(size: 12pt, fill: muted, "PURE DIALOGUE"))
  block(width: 100%, height: 100%,
    inset: (top: 58pt, x: 28pt, bottom: 16pt),
    align(horizon, body))
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
      #text(fill: muted, size: 13pt, tracking: 3pt)[PURE DIALOGUE]
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
  "属性ゼロからの\n純粋対話",
  subtitle: "AI・人間シームレス統合コミュニケーションプラットフォーム",
  author: "石橋憲尚",
  date: "2026-05-25",
)

// 2. 問いかけ
#slide("純粋な対話への問いかけ")[
  #align(center + horizon)[
    #text(size: 28pt, weight: "bold")[
      皆さん、最後に\
      #text(fill: accent)[「自分の属性を1つも気にせず」]\
      誰かと話したのはいつですか？
    ]
    #v(24pt)
    #text(fill: muted, size: 16pt)[
      年齢、性別、声、見た目 ——\
      すべてを忘れて話せた瞬間を思い出してください
    ]
  ]
]

// 3. 社会課題
#slide("孤独と社会不安の深刻化")[
  #grid(columns: (1fr, 1fr), gutter: 20pt)[
    #align(center)[
      #v(16pt)
      #text(size: 48pt, weight: "black", fill: accent)[35.3万人]
      #v(6pt)
      #text(size: 15pt, fill: muted)[不登校児童数（過去最多）2025年]
      #v(20pt)
      #text(size: 48pt, weight: "black", fill: accent2)[2.2万人]
      #v(6pt)
      #text(size: 15pt, fill: muted)[年間孤独死者数（65歳以上）2025年]
    ]
  ][
    #v(10pt)
    #card-box[
      #set text(size: 16pt)
      日本社会では不登校児童と高齢者の孤独死が深刻な社会問題となっています。

      #v(8pt)
      人とのつながりを失った人々が増加し続けている現状を直視する必要があります。
    ]
    #v(12pt)
    #card-box[
      #set text(size: 15pt)
      インターネット時代において、私たちは常に他者と*比較される環境*に置かれています。

      #v(6pt)
      声のコンプレックス、見た目への不安、年齢による偏見——これらが肥大化し、本来の自分を表現することへの恐怖が深刻化しています。
    ]
  ]
]

// 4. 既存SNSの限界
#slide("既存 SNS の限界")[
  #grid(columns: (1fr, 1fr), gutter: 16pt)[
    #card-box[
      #text(fill: accent, weight: "bold")[既存 SNS の特徴]
      #v(6pt)
      #set text(size: 16pt)
      - プロフィールアイコン必須
      - フォロワー数・認知度の可視化
      - 生声での音声通話
      - 即興レスポンスの圧力
    ]
  ][
    #card-box[
      #text(fill: accent2, weight: "bold")[引きこもりの方の困難]
      #v(6pt)
      #set text(size: 16pt)
      - 自己開示への恐怖
      - 比較による劣等感
      - 声を出すことへの抵抗
      - 即座の返答プレッシャー
    ]
  ]
  #v(14pt)
  #align(center)[
    #text(size: 17pt, fill: accent, weight: "bold")[
      本当に傷ついている人には高すぎるハードル
    ]
  ]
]

// 5. ソリューション概要
#slide("ソリューション：属性ゼロの純粋対話")[
  #grid(columns: (1fr, 1fr, 1fr), gutter: 14pt)[
    #card-box[
      #align(center)[
        #text(size: 28pt, fill: accent, weight: "black")[視]
        #v(4pt)
        #text(fill: accent, weight: "bold")[ビジュアルの統一]
      ]
      #v(6pt)
      #set text(size: 15pt)
      共通の美麗な 3D アバターにより、外見による先入観を完全に排除
    ]
  ][
    #card-box[
      #align(center)[
        #text(size: 28pt, fill: accent2, weight: "black")[聴]
        #v(4pt)
        #text(fill: accent2, weight: "bold")[聴覚の標準化]
      ]
      #v(6pt)
      #set text(size: 15pt)
      STT → TTS の音声フィルターにより、声の違いを優しく吸収
    ]
  ][
    #card-box[
      #align(center)[
        #text(size: 28pt, fill: rgb("#44ee88"), weight: "black")[名]
        #v(4pt)
        #text(fill: rgb("#44ee88"), weight: "bold")[情報の非対称性排除]
      ]
      #v(6pt)
      #set text(size: 15pt)
      わかるのは相手の「名前」だけ。年齢・性別・経歴を排除
    ]
  ]
]

// 6. 最大のイノベーション
#slide("最大のイノベーション：AI・人間シームレス統合")[
  #grid(columns: (1fr, 1fr), gutter: 16pt)[
    #card-box[
      #text(fill: accent, weight: "bold")[一人の時は AI が寄り添う]
      #v(6pt)
      #set text(size: 16pt)
      孤独な時間も AI アバターが常に傍に。\
      心理的負担なく、いつでも対話を始められる安心感
    ]
    #v(10pt)
    #card-box[
      #text(fill: accent2, weight: "bold")[複数人時は人間へシームレス移行]
      #v(6pt)
      #set text(size: 16pt)
      他のユーザーがいる時は自然に人間同士の対話へ。\
      *ユーザーは気づかないうちに段階的に*他者との交流へ移行
    ]
  ][
    #v(10pt)
    #text(fill: muted, size: 14pt)[UX 体験の流れ]
    #v(8pt)
    #let step(n, title, desc) = grid(
      columns: (32pt, 1fr), gutter: 8pt,
      align(center, text(fill: accent, weight: "black", size: 18pt)[#n]),
      block[
        #text(weight: "bold")[#title] #linebreak()
        #text(fill: muted, size: 14pt)[#desc]
      ],
    )
    #step("1", "安心", "AI との対話で心を開く")
    #v(6pt)
    #step("2", "慣れ", "対話スキルを自然に習得")
    #v(6pt)
    #step("3", "移行", "気づかぬうちに人間と対話")
    #v(6pt)
    #step("4", "成長", "対人不安を克服し交流拡大")
  ]
]

// 7. デモ・スクリーンショット（旧「何を作ったか」）
#slide("デモ：リアルタイム対話")[
  #grid(columns: (1fr, 1fr), gutter: 16pt)[
    #v(6pt)
    マイク入力に即座に反応するアバターのリップシンク技術と、多彩なペルソナ切り替え機能

    #v(10pt)
    #card-box[
      #set text(size: 16pt)
      - マイク入力 → 即時リップシンク反応
      - ペルソナ切り替え：ツンデレ / 幼児 / お姉さん
      - 統一アバターで自然な対話体験
      - 心理的障壁のない安心コミュニケーション
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

// 8. システム全体構成
#slide("システム全体構成")[
  #align(center + horizon)[
    #image("fig/architecture.png", width: 88%)
  ]
]

// 9. パイプラインの流れ
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

// 10. 音声入力
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

// 11. LLM連携
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

// 12. 3Dフロントエンド
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

// 13. 親密度システム
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
      0〜20：余所余所しい　/　21〜40：普通#linebreak()
      41〜60：親しみ　/　61〜80：温かく甘える#linebreak()
      81〜100：愛情全開
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

// 14. 工夫まとめ
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

// 15. まとめ
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

// 16. 終わり
#end-slide("ご清聴ありがとうございました")[
  #v(14pt)
  #text(fill: muted, size: 17pt)[
    デモ：#link("https://talk.utyujin.com")[talk.utyujin.com]
  ]
]
