const test = require("node:test");
const assert = require("node:assert");
const { subtotal, applyDiscount, itemCount, removeItem } = require("./cart");

test("subtotal sums price times quantity", () => {
  assert.strictEqual(subtotal([{ priceCents: 250, qty: 2 }, { priceCents: 100, qty: 1 }]), 600);
});

test("applyDiscount takes a percentage off", () => {
  assert.strictEqual(applyDiscount(1000, 15), 850);
});

test("applyDiscount rejects out-of-range percentages", () => {
  assert.throws(() => applyDiscount(1000, 101), RangeError);
});

test("itemCount sums quantities", () => {
  assert.strictEqual(itemCount([{ priceCents: 250, qty: 2 }, { priceCents: 100, qty: 3 }]), 5);
  assert.strictEqual(itemCount([]), 0);
});

test("removeItem drops the matching sku", () => {
  const items = [{ sku: "a", priceCents: 100, qty: 1 }, { sku: "b", priceCents: 200, qty: 1 }];
  assert.deepStrictEqual(removeItem(items, "a").map((i) => i.sku), ["b"]);
});
