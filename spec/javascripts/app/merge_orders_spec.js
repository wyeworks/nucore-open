/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
//= require helpers/jasmine-jquery

describe("Merge Orders", function() {
  describe("a page that doesn't have the form", function() {
    fixture.set('');
    return it("does not die", () => new MergeOrder($(".js--edit-order")).initTimeBasedServices());
  });

  return describe("with a valid form", function() {
    fixture.set(`\
<form class="js--edit-order"> \
<input id="quantity" class="js--edit-order__quantity" value="2" /> \
<select id="product" class="js--edit-order__product"> \
<option data-timed-product="false" selected="selected" value="untimed">Untimed Product</option> \
<option data-timed-product="true" value="timed">Timed Product</option> \
</select> \
<input type="text" name="duration" id="duration" class="js--edit-order__duration" value="1" /> \
</form>\
`
    );

    beforeEach(() => new MergeOrder($(".js--edit-order")).initTimeBasedServices());

    it("does not have the duration visible", function() {
      expect($("#duration")).toBeHidden();
      return expect($("#duration")).toBeDisabled();
    });

    return describe("when I switch to a timed product", function() {
      beforeEach(() => $("#product").val("timed").trigger("change"));

      it("will change a quantity to 1 if I switch to a timed product", () => expect($("#quantity").val()).toEqual("1"));

      it("disables the quantity when I switch to a timed product", () => expect($("#quantity")).toBeDisabled());

      it("enables and shows the duration", function() {
        expect($("#duration")).not.toBeDisabled();
        return expect($("#duration")).toBeVisible();
      });

      return describe("and I switch back to a regular product", function() {
        beforeEach(() => $("#product").val("untimed").trigger("change"));

        it("hides and disables the duration", function() {
          expect($("#duration")).toBeDisabled();
          return expect($("#duration")).toBeHidden();
        });

        return it("enables the quantity", () => expect($("#quantity")).not.toBeDisabled());
      });
    });
  });
});
