const test = require("node:test");
const assert = require("node:assert");
const { subtotal, applyDiscount } = require("./cart");

test("subtotal sums price times quantity", () => {
  assert.strictEqual(subtotal([{ priceCents: 250, qty: 2 }, { priceCents: 100, qty: 1 }]), 600);
});

test("applyDiscount takes a percentage off", () => {
  assert.strictEqual(applyDiscount(1000, 15), 850);
});

test("applyDiscount rejects out-of-range percentages", () => {
  assert.throws(() => applyDiscount(1000, 101), RangeError);
});
