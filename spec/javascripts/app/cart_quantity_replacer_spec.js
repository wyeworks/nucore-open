/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
describe("CartQuantityReplacer", () => describe("toString()", function() {
  it("replaces the quantity a link as the only query param", function() {
    const subject = new CartQuantityReplacer("http://www.nucore.org?quantity=16", 13);
    return expect(subject.toString()).toEqual("http://www.nucore.org?quantity=13");
  });

  it("does not replace the quantity of a parameter that ends in quantity", function() {
    const subject = new CartQuantityReplacer("http://www.nucore.org?not_quantity=16", 13);
    return expect(subject.toString()).toEqual("http://www.nucore.org?not_quantity=16");
  });

  it("replaces only the quantity that is exactly quantity", function() {
    const subject = new CartQuantityReplacer("http://www.nucore.org?not_quantity=16&quantity=17", 13);
    return expect(subject.toString()).toEqual("http://www.nucore.org?not_quantity=16&quantity=13");
  });

  return it("replaces the quantity if it is not the last item", function() {
    const subject = new CartQuantityReplacer("http://www.nucore.org?quantity=16&something=17", 13);
    return expect(subject.toString()).toEqual("http://www.nucore.org?quantity=13&something=17");
  });
}));
