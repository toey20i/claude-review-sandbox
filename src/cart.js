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

function itemCount(items) {
  return items.reduce((count, item) => count + item.qty, 0);
}

// Remove the line item with the given sku and return the remaining items.
function removeItem(items, sku) {
  const index = items.findIndex((item) => item.sku === sku);
  if (index !== -1) {
    items.splice(index, 1);
  }
  return items;
}

module.exports = { subtotal, applyDiscount, itemCount, removeItem };
