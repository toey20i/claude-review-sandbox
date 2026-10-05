// Minimal cart. All amounts are integer cents.

function subtotal(items) {
  return items.reduce((sum, item) => sum + item.priceCents * item.qty, 0);
}

function applyDiscount(totalCents, percent) {
  if (percent < 0 || percent > 100) {
    throw new RangeError("percent must be between 0 and 100");
  }
  return Math.round((totalCents * (100 - percent)) / 100);
}

// Total quantity of every item in the cart.
function totalQuantity(items) {
  return items.reduce((n, item) => n + item.qty, 0);
}

module.exports = { subtotal, applyDiscount, totalQuantity };
