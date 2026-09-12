---
name: vibe-modeling
description: Defines domain terms and records significant architectural decisions for the project. Use when defining domain vocabulary, recording architectural decisions, or when other skills need to update the domain model.
---

# Vibe Modeling

Use this skill when the domain model changes. Read the glossary before altering terms. Use concrete examples for non-obvious relationships. Record agreed terms immediately. Propose ADRs only for decisions meeting ADR criteria. Do not use this skill merely to read `CONTEXT.md`.

## File Structure

Most repositories maintain a single context:

```
/
├── CONTEXT.md
├── docs/
│   └── adr/
│       ├── 0001-event-sourced-orders.md
│       └── 0002-postgres-for-write-model.md
└── src/
```

If `CONTEXT-MAP.md` exists at root, the repository contains multiple contexts. The map lists each context and its location:

```
/
├── CONTEXT-MAP.md
├── docs/
│   └── adr/                          ← System-wide decisions
├── src/
│   ├── ordering/
│   │   ├── CONTEXT.md
│   │   └── docs/adr/                 ← Context-specific decisions
│   └── billing/
│       ├── CONTEXT.md
│       └── docs/adr/
```

Create files only when there is content. If `CONTEXT.md` is missing, create it after agreeing on the first term. If `docs/adr/` is missing, create it only when the first ADR is needed.

## During a Session

### Use Direct Language

- Use short, literal sentences for all questions, explanations, and records. Avoid idioms, metaphors, or culturally dependent expressions.
- In `CONTEXT.md`, write every canonical term in `Korean (English)` order. Write Korean first. Write definitions in Korean.
- Use CEFR B1-or-lower vocabulary in Korean terms, definitions, questions, explanations, and records. Apply the CEFR A1–A2 standard only to English names, not Korean.
- All general English names must use everyday CEFR A1–A2 English words. This is required.
- Use an English technical term only when it is clearly used in Korea as the name of that domain. This is the only exception to the English-name rule.

### Compare Against Glossary

If the user uses a term or meaning conflicting with `CONTEXT.md`, surface the conflict immediately. Ask: "`CONTEXT.md`는 `취소 (Cancel)`를 X로 정의한다. X와 Y 중 어느 뜻인가?"

### Clarify Ambiguous Language

If the user uses a term with multiple meanings, propose a single precise canonical term. Ask: "`고객 (Customer)`와 `사용자 (User)` 중 어느 뜻인가? 둘은 다른 개념이다."

### Use Concrete Examples

Use concrete examples when discussing domain relationships. Check edge cases around conceptual boundaries. Ask the user which concept each case falls under.

### Compare with Code

When the user describes how something works, compare their description with the code. Highlight differences: "코드는 `주문 (Order)` 전체를 취소한다. 당신은 주문의 일부를 취소할 수 있다고 했다. 어느 동작이 맞는가?"

### Update CONTEXT.md Immediately

Update `CONTEXT.md` immediately once a term is agreed upon. Do not defer recording. Use the format in [CONTEXT-FORMAT.md](CONTEXT-FORMAT.md).

Keep only glossary terms in `CONTEXT.md`. Exclude implementation details, specs, working notes, and design decisions.

### Propose ADRs Only When Warranted

Do not create ADRs automatically. Propose an ADR only when all three conditions are true:

1. **Hard to change** — Significant cost to reverse the decision later.
2. **Non-obvious from code alone** — Future readers cannot deduce the reasoning from code alone.
3. **Evaluated real alternatives** — Real alternatives were evaluated and one was chosen for specific reasons.

If any condition is missing, do not propose an ADR. Use the format in [ADR-FORMAT.md](ADR-FORMAT.md).
