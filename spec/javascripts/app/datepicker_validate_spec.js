/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
//= require helpers/jasmine-jquery

describe("DatePickerValidate", function() {
  describe("with no constraints on the picker", function() {
    fixture.set(`\
<div class="control-group"> \
<input id="picker1" class="datepicker__data" value="06/22/2017" /> \
</div>\
`
    );

    beforeEach(() => DatePickerData.activate());

    it("has an error if the date is invalid", function() {
      $("#picker1").val("06/22/17").trigger("change");
      expect($(".control-group")).toHaveClass("error");
      return expect($(".help-inline")).toHaveText("invalid date format");
    });

    return it("is changed to something valid", function() {
      $("#picker1").val("07/23/2016").trigger("change");
      return expect($(".control-group")).not.toHaveClass("error");
    });
  });

  describe("with min and maxDate constraints on the picker", function() {
    fixture.set(`\
<div class="control-group"> \
<input id="picker1" class="datepicker__data" value="06/22/2017" \
data-min-date="2017-01-01" data-max-date="2017-12-31" /> \
</div>\
`
    );

    beforeEach(() => DatePickerData.activate());

    it("does not have an error if in the range", function() {
      $("#picker1").val("06/22/2017").trigger("change");
      return expect($(".control-group")).not.toHaveClass("error");
    });

    it("has an error if the date is before the min date", function() {
      $("#picker1").val("06/22/2016").trigger("change");
      expect($(".control-group")).toHaveClass("error");
      return expect($(".help-inline")).toHaveText(/cannot be before/);
    });

    return it("has an error if the date is after the max date", function() {
      $("#picker1").val("07/23/2018").trigger("change");
      expect($(".control-group")).toHaveClass("error");
      return expect($(".help-inline")).toHaveText(/cannot be after/);
    });
  });

  return describe("with two pickers with different options", function() {
    fixture.set(`\
<div id="control1" class="control-group"> \
<input id="picker1" class="datepicker__data" value="06/22/2017" \
data-min-date="2017-01-01" data-max-date="2017-12-31" /> \
</div> \
<div id="control2" class="control-group"> \
<input id="picker2" class="datepicker__data" value="04/13/2016" \
data-min-date="2016-01-01" data-max-date="2016-12-31" /> \
</div>\
`
    );

    beforeEach(() => DatePickerData.activate());

    describe("picker1", function() {
      it("does not have an error if in its own range", function() {
        $("#picker1").val("06/22/2017").trigger("change");
        return expect($("#control1")).not.toHaveClass("error");
      });

      return it("has an error if it is within the others range, but not its own", function() {
        $("#picker1").val("06/22/2016").trigger("change");
        return expect($("#control1")).toHaveClass("error");
      });
    });

    return describe("picker2", function() {
      it("does not have an error if in its own range", function() {
        $("#picker2").val("06/22/2016").trigger("change");
        return expect($("#control2")).not.toHaveClass("error");
      });

      return it("has an error if it is within the others range, but not its own", function() {
        $("#picker2").val("06/22/2017").trigger("change");
        return expect($("#control2")).toHaveClass("error");
      });
    });
  });
});
