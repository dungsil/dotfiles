# Deep Module Vocabulary

Design **deep modules**: lots of behavior behind small interfaces, placed at clean boundaries, tested through those interfaces. The goal is one interface covering many callers, fixes that stay in one place, and easier tests.

In user-facing text (HTML reports, cards, questions, legends), use the Korean architectural terms and Korean plain explanations below. Do not attach English specialist terms such as `seam`, `leverage`, `locality`, `depth`, or `golden` as labels. Use only terms already used in Korean with these meanings, such as `모듈`, `인터페이스`, `어댑터`, and `경계`. Do not invent new translated nouns.

## Table of Contents

- Glossary — module, interface, implementation, depth, boundary, adapter
- Deep vs Shallow
- Principles
- Designing for Testability
- Relationships
- Rejected Phrasings

## Glossary

**모듈** — Anything with an interface and an implementation. A function, class, package, or cross-layer slice. _Avoid_: unit, component, service.

**인터페이스** — Everything callers must know to use the module: not just types, but invariants, ordering, error modes, configuration, and performance. _Avoid_: API, signature (type surface only).

**구현** — The code inside the module. Distinct from **어댑터**: a small adapter can wrap a large implementation (Postgres repository), or a large adapter can wrap a small implementation (in-memory fake). Use "어댑터" when talking about the boundary; otherwise "구현".

**깊이** — How much behavior a caller can run per unit of interface learned. **깊다** when a lot sits behind a small interface. **얕다** when the interface is as complex as the implementation. In user-facing text say `깊다` / `얕다`, not `depth`.

**경계** — A place you can change behavior without editing that place; where the module's interface sits. Where to put it is a separate decision from what sits behind it. In user-facing text say `경계` or `테스트하는 곳`. Do not say `seam`. For a DDD bounded context, say `바운디드 컨텍스트` so it does not mix with this boundary.

**어댑터** — The concrete thing that fills an interface at a boundary. Names the role, not what is inside.

Do not mint nouns for what callers gain or what maintainers gain. Write `인터페이스 하나로 여러 호출을 처리한다` and `고칠 곳이 한곳이다`.

## Deep vs Shallow

**깊은 모듈** = **작은 인터페이스** + **많은 구현**:

```
┌─────────────────────┐
│   작은 인터페이스    │  ← 메서드 적음, 매개변수 단순
├─────────────────────┤
│                     │
│  깊은 구현           │  ← 복잡한 로직을 숨김
│                     │
└─────────────────────┘
```

**얕은 모듈** = **큰 인터페이스** + **적은 구현** (피하라):

```
┌─────────────────────────────────┐
│       큰 인터페이스              │  ← 메서드 많음, 매개변수 복잡
├─────────────────────────────────┤
│  얇은 구현                       │  ← 전달만 함
└─────────────────────────────────┘
```

When designing interfaces, ask in Korean:

- 메서드 수를 줄일 수 있는가?
- 매개변수를 단순화할 수 있는가?
- 더 많은 복잡성을 안에 숨길 수 있는가?

## Principles

- **`깊이는 구현이 아니라 인터페이스의 속성이다.`** Internals may be small and swappable — they just are not public. A module may have an outer `바깥 경계` plus inner `안쪽 경계` used only by its own tests.
- **`삭제 테스트`.** Imagine deleting the module. If complexity vanishes, it was a pass-through. If complexity reappears across N callers, it was earning its keep.
- **`인터페이스가 테스트하는 면이다.`** Callers and tests pass through the same boundary. If you want to test *past* the interface, the module is probably misshapen.
- **`어댑터가 하나면 경계를 만들지 마라.`** Add one only when there are two (usually production and test).

## Designing for Testability

1. **Accept dependencies rather than creating them.**

   ```typescript
   // 테스트 가능
   function processOrder(order, paymentGateway) {}

   // 테스트 어려움
   function processOrder(order) {
     const gateway = new StripeGateway();
   }
   ```

2. **Return results rather than causing side effects.**

   ```typescript
   // 테스트 가능
   function calculateDiscount(cart): Discount {}

   // 테스트 어려움
   function applyDiscount(cart): void {
     cart.total -= discount;
   }
   ```

3. **Keep the surface small.** Fewer methods = fewer tests. Simpler parameters = simpler setup.

## Relationships

- A **모듈** has one **인터페이스**.
- **깊이** is measured against that interface.
- A **경계** is where that interface sits.
- An **어댑터** fills the interface at the boundary.
- **깊이** lets callers do more with one interface, and keeps fixes in one place.

## Rejected Phrasings

- **`구현 줄 수 대비 인터페이스 줄 수로 깊이를 재기`** (Ousterhout): rewards bloated implementations. Measure by what callers gain.
- **TypeScript `interface`나 public 메서드만 `인터페이스`로 보기**: too narrow.
- **영어 전문용어를 라벨로 붙이기** (`seam`, `leverage`, `locality`, `depth`, `golden`).
- **새 번역 명사 만들기** (`이음새`, `한곳 모임`, `호출자 이득`). Use ordinary words and Korean plain sentences.
