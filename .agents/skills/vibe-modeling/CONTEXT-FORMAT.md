# CONTEXT.md Format

## Structure

```md
# {컨텍스트 이름 (Context Name)}

{이 컨텍스트가 다루는 영역과 필요한 이유를 한두 문장으로 쓴다.}

## 용어

**주문 (Order)**:
고객이 살 물건과 수량을 정한 요청이다.
_피할 표현_: 구매, 거래

**청구서 (Bill)**:
상품을 보낸 뒤 고객에게 보내는 결제 요청이다.
_피할 표현_: 명세서, 결제 요청

**고객 (Customer)**:
주문을 하는 개인 또는 조직이다.
_피할 표현_: 손님, 구매자, 계정
```

## Rules

- Write all canonical terms in `Korean (English)` order. Write definitions in Korean.
- Use CEFR B1-or-lower vocabulary in Korean terms, definitions, questions, explanations, and records. Apply the CEFR A1–A2 standard only to English names, not Korean.
- All general English names must use everyday CEFR A1–A2 English words. The only exception is an English technical term clearly used in Korea as the name of that domain. Replace unfamiliar or overly technical English with simple English.
- Write short, literal sentences in questions, explanations, and records. Avoid idioms, metaphors, or culturally dependent expressions.
- Write definitions in 1–2 sentences. State what the term is, not what it does.
- If multiple names exist for one concept, choose one canonical term and list alternatives under `_피할 표현_`.
- Place only terms and definitions in `CONTEXT.md`. Do not include implementation details, specs, working notes, or design decisions.
- Include only terms unique to this context. Omit general programming concepts like timeouts, error types, or utility patterns.
- Group related terms under subheadings if numerous. Use a flat list for a single focused area.

## Single or Multiple Contexts

**Single Context:** Most repositories maintain a single `CONTEXT.md` at repository root.

**Multiple Contexts:** `CONTEXT-MAP.md` at repository root describes each context, its location, and relationships:

```md
# 컨텍스트 지도

## 컨텍스트

- [주문 (Order)](./src/ordering/CONTEXT.md) — 고객 주문을 받고 상태를 관리한다.
- [청구 (Bill)](./src/billing/CONTEXT.md) — 청구서를 만들고 결제를 처리한다.
- [배송 (Delivery)](./src/fulfillment/CONTEXT.md) — 물건을 고르고 보낸다.

## 관계

- **주문 (Order) → 배송 (Delivery)**: 주문 (Order)은 새 주문 정보를 배송 (Delivery)에 보낸다. 배송 (Delivery)은 물건을 고르고 발송을 시작한다.
- **배송 (Delivery) → 청구 (Bill)**: 배송 (Delivery)은 발송 정보를 청구 (Bill)에 보낸다. 청구 (Bill)은 청구서를 만든다.
- **주문 (Order) ↔ 청구 (Bill)**: 고객 번호 (Customer ID)와 금액 (Money)을 함께 쓴다.
```

Selection criteria:

- Read `CONTEXT-MAP.md` if present to find contexts.
- Use single context if only root `CONTEXT.md` exists.
- If neither exists, create root `CONTEXT.md` upon agreeing on the first term.

If multiple contexts exist, determine which context the current topic belongs to. Ask the user if unclear.
