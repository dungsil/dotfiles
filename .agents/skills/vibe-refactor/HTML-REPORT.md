# HTML Report Format

Architecture reviews render as a single self-contained HTML file in the OS temporary directory. Tailwind and Mermaid load via CDN. Mermaid handles graph-shaped diagrams reliably, while bespoke divs and inline SVGs handle editorial visualizations (mass diagrams, cross-sections). Mix both — do not rely solely on Mermaid to avoid uniformity.

Write the report in Korean. Titles, legends, cards, outcomes, and diagram labels must all be Korean. CSS class names may stay in English.

## Table of Contents

- Scaffolding — Self-contained HTML skeleton
- Header — Report title block
- Candidate Cards — Markup per candidate
- Diagram Patterns — Mermaid graphs, bespoke boxes, cross-sections, mass diagrams, folding call graphs
- Style Guide — Tailwind conventions
- Top Recommendation Section
- Tone

## Scaffolding

```html
<!doctype html>
<html lang="ko">
  <head>
    <meta charset="utf-8" />
    <title>아키텍처 검토 — {{repo name}}</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <script type="module">
      import mermaid from "https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.esm.min.mjs";
      mermaid.initialize({ startOnLoad: true, theme: "neutral", securityLevel: "loose" });
    </script>
    <style>
      /* Tailwind가 깔끔하게 처리하지 못하는 작은 커스텀 층:
         점선 경계, 손그림 느낌의 화살촉 등 */
      .join { stroke-dasharray: 4 4; }
      .leak { stroke: #dc2626; }
      .deep { background: linear-gradient(135deg, #0f172a, #1e293b); }
    </style>
  </head>
  <body class="bg-stone-50 text-slate-900 font-sans">
    <main class="max-w-5xl mx-auto px-6 py-12 space-y-12">
      <header>...</header>
      <section id="candidates" class="space-y-10">...</section>
      <section id="top-recommendation">...</section>
    </main>
  </body>
</html>
```

## Header

Repository name, date, and a concise Korean legend: `실선 박스 = 모듈`, `점선 = 경계`, `빨간 화살표 = 새어나감`, `굵은 어두운 박스 = 깊은 모듈`. No introductory paragraphs — straight to candidates.

## Candidate Cards

Diagrams carry the weight. Prose is sparse and written in plain Korean. Use the concepts from [VOCABULARY.md](VOCABULARY.md) in Korean plain words — do not attach English specialist terms as labels.

Each candidate is an `<article>`:

- **제목** — Short, names the deepening (e.g. `주문 접수 파이프라인 접기`).
- **배지 행** — Recommendation strength (`추천` = emerald, `검토` = amber, `불확실` = slate), plus dependency classification tags (`프로세스 안`, `로컬 대체`, `포트와 어댑터`, `모의`).
- **파일** — Monospace list, `font-mono text-sm`.
- **전/후 다이어그램** — The core. Two columns, side by side. See patterns below.
- **문제** — One sentence. What hurts.
- **해결** — One sentence. What changes.
- **성과** — Bullets, each ≤8 words. E.g. `테스트가 인터페이스 하나만 본다`, `가격 로직 새어나감 멈춤`, `얕은 전달 모듈 4개 삭제`.
- **ADR 콜아웃** (where applicable) — One line in an amber box.

No explanatory paragraphs. If a diagram requires a paragraph to be understood, redraw the diagram.

## Diagram Patterns

Choose patterns fitting each candidate. Mix them. Do not make every diagram look the same — diversity is the point.

Keep code identifiers (type and file names) as-is. Write concept labels, including `깊은 모듈`, `경계`, and `구현`, in Korean.

### Mermaid Graphs (Workhorse for dependencies / call flows)

Use Mermaid `flowchart` or `graph` when the point is "X calls Y, Y calls Z, observe the tangle". Wrap in Tailwind-styled cards so they don't look jarring. Use classDefs to color leaking edges red and deep modules dark. Sequence diagrams fit `전: 6번 왕복; 후: 1번`.

```html
<div class="rounded-lg border border-slate-200 bg-white p-4">
  <pre class="mermaid">
    flowchart LR
      A[OrderHandler] --> B[OrderValidator]
      B --> C[OrderRepo]
      C -.leak.-> D[PricingClient]
      classDef leak stroke:#dc2626,stroke-width:2px;
      class C,D leak
  </pre>
</div>
```

### Bespoke Boxes and Arrows (When Mermaid layouts fight you)

Modules as `<div>`s with borders and Korean labels. Arrows as inline SVG `<line>` or `<path>` positioned absolutely over relative containers. Use when the `후` diagram needs a single thick-bordered `깊은 모듈` with grayed-out internals — Mermaid struggles to render that weight cleanly.

### Cross-Sections (Great for layered shallowness)

Stack of horizontal bands (`h-12 border-l-4`) showing layers calls pass through. `전`: 6 thin layers doing nothing. `후`: 1 thick band labeled `통합된 책임`.

### Mass Diagrams (When interface is as broad as implementation)

Two rectangles per module — one for interface surface area, one for implementation. `전`: interface rectangle almost as tall as implementation rectangle (`얕음`). `후`: short interface rectangle, tall implementation rectangle (`깊음`).

### Folding Call Graphs

`전`: function call tree rendered as nested boxes. `후`: the same tree folded into a single box, with calls now internal and faded inside.

## Style Guide

- Editorial feel rather than corporate dashboard. Generous whitespace. Optional serif headers (`font-serif` pairs well with stone/slate).
- Restrained color palette: one accent color (emerald or indigo), red for leaks, amber for warnings.
- Maintain diagram heights at ~320px so before/after sit comfortably side by side without scrolling.
- Use `text-xs tracking-wide` for Korean module labels in diagrams. Do not render English jargon in all caps (`SEAM`, `MODULE`).
- Scripts restricted to Tailwind CDN and Mermaid ESM import. The report is otherwise static — no app code, no interactivity beyond Mermaid's own rendering.

## Top Recommendation Section

One larger card. Candidate name, one-sentence rationale, anchor link to card. Nothing more.

## Tone

Plain and concise Korean. Use CEFR B1-or-lower vocabulary in Korean expressions. Do not use idioms, metaphors, or expressions whose meaning depends on culture.

Follow the concepts in [VOCABULARY.md](VOCABULARY.md), but unpack them in Korean user-facing text.

**Do not write in user-facing text:** `seam`, `leverage`, `locality`, `depth`, `golden`, `deepening`.

**Fine to use:** `모듈`, `인터페이스`, `구현`, `어댑터`.

**Idiomatic phrasing:**

- "주문 접수 모듈이 얕다 — 인터페이스가 구현과 거의 같다."
- "가격이 경계 너머로 새어나간다."
- "심화: 인터페이스 하나, 테스트할 곳 하나."
- "어댑터가 둘이면 경계를 둔다: 프로덕션은 HTTP, 테스트는 메모리."

**Outcome bullets** name the gain in easy Korean: *"버그가 한 모듈에 모인다"*, *"인터페이스 하나, 호출 지점 여러 개"*, *"인터페이스가 줄고 구현이 전달 모듈을 흡수한다"*. "고치기 쉬워짐" is fine. Do not prefix bullets with English labels such as `locality:` or `leverage:`.

No hedging, no preambles, no "it is worth noting that...". If a sentence can be a bullet, make it a bullet. If a bullet can be trimmed, trim it.
