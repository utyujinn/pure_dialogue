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
  place(top + left,  dx: 28pt, dy: 16pt,
    text(size: 20pt, weight: "bold", fill: fg, header))
  place(top + right, dx: -20pt, dy: 16pt,
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
  "声も、立場も、過去も\n脱ぎ捨てる。",
  subtitle: "AI・人間シームレス統合コミュニケーションプラットフォーム「Pure Dialogue」",
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
      #text(size: 48pt, weight: "black", fill: accent2)[7.6万人]
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
      - 他人との深いかかわり
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

// 6. 誰のためのプラットフォームか
#slide("誰のための空間か")[
  #grid(columns: (1fr, 1fr, 1fr), gutter: 12pt)[
    #card-box[
      #align(center)[#text(size: 26pt, fill: accent, weight: "black")[安心]]
      #v(4pt)
      #text(fill: accent, weight: "bold")[トラウマ・社会不安を持つ人へ]
      #v(6pt)
      #set text(size: 14pt)
      叱責・罵倒されるリスクを最小化。#linebreak()
      AI の穏やかな応答から始め、#linebreak()
      少しずつ心を開いていける。
    ]
  ][
    #card-box[
      #align(center)[#text(size: 26pt, fill: accent2, weight: "black")[平等]]
      #v(4pt)
      #text(fill: accent2, weight: "bold")[声にコンプレックスがある人へ]
      #v(6pt)
      #set text(size: 14pt)
      TTS で全員の声が統一されるため#linebreak()
      地声を晒す必要がない。#linebreak()
      「声」ではなく「言葉」で向き合える。
    ]
  ][
    #card-box[
      #align(center)[#text(size: 26pt, fill: rgb("#44ee88"), weight: "black")[共生]]
      #v(4pt)
      #text(fill: rgb("#44ee88"), weight: "bold")[世代を超えた対話]
      #v(6pt)
      #set text(size: 14pt)
      老若男女が属性を超えてフラットに対話。#linebreak()
      世代間理解が深まり、#linebreak()
      助け合う意識が自然と芽生える。
    ]
  ]
  #v(18pt)
  #align(center)[
    #text(size: 18pt, fill: fg, weight: "bold")[
      #text(fill: accent)[だれもが]、最初の一歩を踏み出せる空間。
    ]
  ]
]

// 7. 最大のイノベーション
#slide("最大のイノベーション：対人コミュニケーションのリハビリ")[
  #grid(columns: (3fr, 2fr), gutter: 20pt)[
    #let step(n, col, title, desc) = block(
      fill: col.transparentize(88%),
      stroke: 0.5pt + col.transparentize(60%),
      inset: 10pt, radius: 7pt, width: 100%,
      grid(columns: (28pt, 1fr), gutter: 8pt,
        align(center, text(fill: col, weight: "black", size: 20pt)[#n]),
        block[
          #text(weight: "bold", fill: col)[#title] #linebreak()
          #text(fill: fg, size: 15pt)[#desc]
        ],
      )
    )
    #step("1", accent,        "安心",  [AI 相手に、安全な場所で心を開く])
    #v(8pt)
    #step("2", accent2,       "慣れ",  [同じ画面・同じ声のまま、裏が人間に切り替わる])
    #v(8pt)
    #step("3", rgb("#44ee88"), "気づき", [「もしかして…人間？」と思ったときには繋がれている])
    #v(8pt)
    #step("4", fg,            "成長",  [対人不安を克服し、交流が広がる])
  ][
    #v(8pt)
    #card-box[
      #text(fill: accent2, weight: "bold")[なぜ 既存SNS ではダメか]
      #v(6pt)
      #set text(size: 15pt)
      多くのSNS は「すでに話せる人」向け。#linebreak()
      #v(4pt)
      Pure Dialogue は「まだ話せない人」が #linebreak()
      *気づかないうちに* 踏み出せる設計。
      #v(6pt)
      共通の 3D 空間・親密度・AI の温かさが #linebreak()
      セーフティネットになっている。
    ]
  ]
]

// 8. デモ・スクリーンショット（旧「何を作ったか」）
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
  ][
    #align(center)[
      #image("fig/screenshot.png", width: 100%)
      #text(fill: muted, size: 11pt)[アプリのスクリーンショット]
    ]
  ]
]

// 9. 技術アーキテクチャ
#slide("技術アーキテクチャ")[
  #align(center + horizon)[
    #image("fig/architecture.png", width: 95%)
  ]
]

// 10. 機能紹介
#let feat-img(path, label, col, max-h: none) = block(width: 100%)[
  #block(
    stroke: 1pt + col.transparentize(60%),
    radius: 6pt,
    clip: true,
    width: 100%,
    ..if max-h != none { (height: max-h) },
    if max-h != none {
      image(path, width: 100%, height: 100%, fit: "contain")
    } else {
      image(path, width: 100%)
    },
  )
  #align(center, text(fill: col, size: 12pt, weight: "bold")[#label])
]

#slide("実装した主な機能")[
  // 左(2fr)：ペルソナ | リップシンク＋親密度　右(1fr)：音声モデル縦長
  #grid(columns: (2fr, 1fr), gutter: 14pt)[
    // 左：ペルソナ(左列) と リップシンク＋親密度(右列) を横並び
    #grid(columns: (1fr, 1fr), gutter: 10pt)[
      #feat-img("fig/persona.png", "ペルソナ切り替え（6種）", accent, max-h: 160pt)
      #v(8pt)
      #feat-img("fig/model.png", "AI モデル選択", accent2, max-h: 130pt)
    ][
      #feat-img("fig/lipsync.png", "リップシンク", accent)
      #v(8pt)
      #feat-img("fig/affinity.png", "親密度システム", accent2, max-h: 140pt)
    ]
  ][
    // 右：音声モデル選択 を縦長1枚
    #feat-img("fig/soundmodel.png", "音声モデル選択", accent2, max-h: 350pt)
  ]
]

// 11. 機能詳細
#slide("注目機能の詳細")[
  #set text(size: 13pt)
  #set par(leading: 0.55em, spacing: 0.7em)
  #let feat(col, title, body) = block(
    stroke: (left: 3pt + col),
    inset: (left: 10pt, top: 2pt, bottom: 2pt),
    width: 100%,
  )[
    #text(fill: col, weight: "bold", size: 14pt)[#title]
    #v(1pt)
    #body
  ]
  #grid(columns: (1fr, 1fr), gutter: 12pt)[
    #feat(accent, "ペルソナ切り替え（6種）")[
      お姉ちゃん・知的・幼児・ツンデレ・先生・大人なお姉さん。切り替えと同時に会話履歴をリセットし、システムプロンプトを差し替えることで人格を即座に変更できる。
    ]
    #v(7pt)
    #feat(accent, "リアルタイム・リップシンク")[
      マイク音声の RMS をフレームごとに計算し、VRM モデルの口形態素（`vrc.v_aa`）に lerp で追従。発話中は自然に口が動き、沈黙時は閉じる。
    ]
    #v(7pt)
    #feat(accent2, "AI・人間シームレス切り替え")[
      1人接続時は AI が応答。2人以上になると自動で人間同士の中継モードへ。STT → TTS を経由するため声質の差が吸収され、全員が統一アバター音声で届く。
    ]
  ][
    #feat(accent2, "親密度システム")[
      会話ターンごとに LLM が +1 / 0 / −1 を評価。Cookie に保存され次回も引き継がれる。5段階の関係性テキストをシステムプロンプトに付加し、キャラクターの態度がリアルタイムに変化する。
    ]
    #v(7pt)
    #feat(rgb("#44ee88"), "AIモデル・音声モデルの切り替え")[
      設定パネルから LLM モデル（gemma4 など）と TTS エンジン（VoiceVox / IrodoriTTS）をその場で変更可能。切り替えは即時反映され、次の発話から新しいモデルで応答する。
    ]
  ]
]

// 12. まとめ
#slide("Pure Dialogue が目指すもの")[
  #grid(columns: (1fr, 1fr), gutter: 16pt)[
    #card-box[
      #text(fill: accent, weight: "bold")[これは単なる「チャットツール」ではない]
      #v(8pt)
      #set text(size: 16pt)
      声を奪われた人、#linebreak()
      居場所を失った人が#linebreak()
      社会と再接続するための#linebreak()
      #v(4pt)
      #text(size: 20pt, weight: "black", fill: accent)[*新しい福祉インフラ*]
    ]
    #v(10pt)
    #card-box[
      #text(fill: accent2, weight: "bold")[今後の展望]
      #v(4pt)
      #set text(size: 15pt)
      - 文章から感情・表情の モデル反映
      - 長期記憶（会話サマリー永続化）
    ]
  ][
    #align(center + horizon)[
      #v(10pt)
      #text(size: 22pt, weight: "black")[
        AI だと思って話していたら、#linebreak()
        #v(6pt)
        #text(fill: accent)[いつの間にか]#linebreak()
        世界と繋がっていた。
      ]
      #v(20pt)
      #text(fill: muted, size: 15pt)[
        だれでも、だれとでも、対等に。
      ]
    ]
  ]
]

// 10. 終わり
#end-slide("ご清聴ありがとうございました")[
  #v(10pt)
  #text(size: 20pt, weight: "black")[
    だれでも、だれとでも、対等に。
  ]
  #v(16pt)
  #text(fill: muted, size: 17pt)[
    デモ：#link("https://talk.utyujin.com")[talk.utyujin.com]
  ]
]
