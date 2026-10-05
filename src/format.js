const { toDollars } = require("./money");

// Display only: renders a price label such as "$12.50". Never used for arithmetic.
function priceLabel(cents) {
  return `$${toDollars(cents).toFixed(2)}`;
}

module.exports = { priceLabel };
