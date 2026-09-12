# When to Mock

Mock only at system boundaries:

- External APIs (payments, email, etc.)
- Databases (prefer test DBs when practical)
- Time / randomness
- File system (sometimes)

What NOT to mock:

- Classes/modules you authored
- Internal collaborators
- Anything you control

## Designing for Mockability

Design interfaces that are easy to mock at system boundaries:

**1. Use Dependency Injection**

Pass external dependencies rather than instantiating them internally:

```typescript
// Easy to mock
function processPayment(order, paymentClient) {
  return paymentClient.charge(order.total);
}

// Hard to mock
function processPayment(order) {
  const client = new StripeClient(process.env.STRIPE_KEY);
  return client.charge(order.total);
}
```

**2. Prefer SDK-Style Interfaces over Generic Fetch Helpers**

Instead of one generic function with conditional logic, create specific functions for each external operation:

```typescript
// Good: each function is independently mockable
const api = {
  getUser: (id) => fetch(`/users/${id}`),
  getOrders: (userId) => fetch(`/users/${userId}/orders`),
  createOrder: (data) => fetch('/orders', { method: 'POST', body: data }),
};

// Bad: mocking requires conditional logic
const api = {
  fetch: (endpoint, options) => fetch(endpoint, options),
};
```

What the SDK approach provides:
- Each mock returns one specific shape
- No conditional logic in test setups
- Easier to identify which endpoints a test uses
- Per-endpoint type safety
