/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
window.CartQuantityReplacer = class CartQuantityReplacer {
  constructor(originalPath, newQuantity) { this.originalPath = originalPath; this.newQuantity = newQuantity; undefined; }

  toString() {
    return this.originalPath.replace(/\bquantity=\d+(&|$)/, `quantity=${this.newQuantity}$1`);
  }
};

window.Cart = class Cart {
  constructor(cartSelector) {
    this.$cart = $(cartSelector);
    this.$cart.find("[data-quantity-field]").each(this.setupQuantityListeners);
  }

  setupQuantityListeners(_i, link) {
    const $link = $(link);
    const $quantityField = $("#" + $(link).data("quantity-field"));
    const originalHref = $link.attr("href");

    return $quantityField.change(function(e) {
      const newQuantity = parseInt($quantityField.val());

      if (newQuantity > 0) {
        return $link
          .removeClass("disabled")
          .attr("href", new CartQuantityReplacer(originalHref, newQuantity));

      } else {
        return $link
          .addClass("disabled")
          .removeAttr("href");
      }
    });
  }
};

$(() => new Cart(".js--cart"));
