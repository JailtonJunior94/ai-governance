import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { Money, Payment, InvalidTransitionError } from "./entity.js";

describe("Money", () => {
  it("creates valid money", () => {
    const m = Money.create(1000, "BRL");
    assert.equal(m.amount, 1000);
    assert.equal(m.currency, "BRL");
  });

  it("rejects negative amount", () => {
    assert.throws(() => Money.create(-1, "BRL"), /non-negative/);
  });

  it("rejects empty currency", () => {
    assert.throws(() => Money.create(100, ""), /currency/);
  });
});

describe("Payment", () => {
  const validAmount = Money.create(500, "USD");

  it("creates with pending status", () => {
    const p = Payment.create("pay-1", "cust-1", validAmount);
    assert.equal(p.status, "pending");
  });

  it("rejects empty id", () => {
    assert.throws(() => Payment.create("", "cust-1", validAmount), /id/);
  });

  it("rejects empty customerId", () => {
    assert.throws(() => Payment.create("pay-1", "", validAmount), /customerId/);
  });

  it("confirms from pending", () => {
    const p = Payment.create("pay-1", "cust-1", validAmount);
    p.confirm();
    assert.equal(p.status, "confirmed");
  });

  it("fails to confirm from confirmed", () => {
    const p = Payment.create("pay-1", "cust-1", validAmount);
    p.confirm();
    assert.throws(() => p.confirm(), InvalidTransitionError);
  });

  it("cancels from pending", () => {
    const p = Payment.create("pay-1", "cust-1", validAmount);
    p.cancel();
    assert.equal(p.status, "cancelled");
  });

  it("fails to cancel from cancelled", () => {
    const p = Payment.create("pay-1", "cust-1", validAmount);
    p.cancel();
    assert.throws(() => p.cancel(), InvalidTransitionError);
  });
});
