const test = require("node:test");
const assert = require("node:assert");
const { priceLabel } = require("./format");

test("priceLabel renders dollars with two decimals", () => {
  assert.strictEqual(priceLabel(1250), "$12.50");
  assert.strictEqual(priceLabel(5), "$0.05");
});
