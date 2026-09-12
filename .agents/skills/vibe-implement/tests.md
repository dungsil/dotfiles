# Good Tests and Bad Tests

## Good Tests

**Integration style**: test against real interfaces rather than mocking internal parts.

```typescript
// Good: tests observable behavior
test("user can checkout with valid cart", async () => {
  const cart = createCart();
  cart.add(product);
  const result = await checkout(cart, paymentMethod);
  expect(result.status).toBe("confirmed");
});
```

Characteristics:

- Tests behavior callers/users care about
- Uses public APIs only
- Endures internal refactoring
- Describes what it does rather than how it works
- One logical assertion per test

## Bad Tests

**Testing implementation details**: coupled to internal structures.

```typescript
// Bad: tests implementation details
test("checkout calls paymentService.process", async () => {
  const mockPayment = jest.mock(paymentService);
  await checkout(cart, payment);
  expect(mockPayment.process).toHaveBeenCalledWith(cart.total);
});
```

Red flags:

- Mocking internal collaborators
- Testing private methods
- Asserting call counts / order
- Refactoring without behavioral changes breaks tests
- Test names describe mechanics rather than capabilities
- Verifying via external channels instead of interfaces

```typescript
// Bad: bypasses interface for verification
test("createUser saves to database", async () => {
  await createUser({ name: "Alice" });
  const row = await db.query("SELECT * FROM users WHERE name = ?", ["Alice"]);
  expect(row).toBeDefined();
});

// Good: verifies through public interface
test("createUser makes user retrievable", async () => {
  const user = await createUser({ name: "Alice" });
  const retrieved = await getUser(user.id);
  expect(retrieved.name).toBe("Alice");
});
```

**Tautological tests**: expected value merely repeats the implementation, so tests pass by definition.

```typescript
// Bad: recomputes expected value the same way code does
test("calculateTotal sums line items", () => {
  const items = [{ price: 10 }, { price: 5 }];
  const expected = items.reduce((sum, i) => sum + i.price, 0);
  expect(calculateTotal(items)).toBe(expected);
});

// Good: expected value is an independently known literal
test("calculateTotal sums line items", () => {
  expect(calculateTotal([{ price: 10 }, { price: 5 }])).toBe(15);
});
```
