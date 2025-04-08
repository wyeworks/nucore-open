/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
describe("Cart", function() {
  fixture.set(`\
<form class="js--cart"> \
<input id="quantity" value="1"> \
<a id="link" href="?quantity=16" data-quantity-field="quantity"> \
</form>\
`
  );

  beforeEach(() => new Cart(".js--cart"));

  return describe("changing the quantity", function() {
    it("updates the path for a positive quantity", function() {
      $("#quantity").val("10").trigger("change");
      return expect($("#link").attr("href")).toMatch(/quantity=10$/);
    });

    describe("to a negative value", function() {
      beforeEach(() => $("#quantity").val("-10").trigger("change"));

      it("unsets the link's href", () => expect($("#link").attr("href")).toBeUndefined());

      return it("adds the disabled class", () => expect($("#link").hasClass("disabled")).toBeTruthy());
    });

    describe("to a blank value", function() {
      beforeEach(() => $("#quantity").val(" ").trigger("change"));

      it("unsets the link's href", () => expect($("#link").attr("href")).toBeUndefined());

      return it("adds the disabled class", () => expect($("#link").hasClass("disabled")).toBeTruthy());
    });

    describe("to a non-integer", function() {
      beforeEach(() => $("#quantity").val("abc").trigger("change"));

      it("unsets the link's href", () => expect($("#link").attr("href")).toBeUndefined());

      return it("adds the disabled class", () => expect($("#link").hasClass("disabled")).toBeTruthy());
    });

    return describe("to an invalid value and back to valid", function() {
      beforeEach(function() {
        $("#quantity").val("-10").trigger("change");
        return $("#quantity").val("17").trigger("change");
      });

      it("sets the link's href", () => expect($("#link").attr("href")).toMatch(/quantity=17$/));

      return it("does not have the disabled class", () => expect($("#link").hasClass("disabled")).toBeFalsy());
    });
  });
});
