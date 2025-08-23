/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS205: Consider reworking code to avoid use of IIFEs
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */

//= require helpers/jasmine-jquery

describe("DateTimeSelectionWidgetGroup", function() {
  fixture.set(`\
<form> \
<input name="date" value="11/13/2015"> \
<input name="hour" value="9"> \
<input name="minute" value="15"> \
<input name="meridian" value="AM"> \
</form>\
`
  );

  beforeEach(function() {
    const $date = $("input[name=date]", fixture.el);
    const $hour = $("input[name=hour]", fixture.el);
    const $minute = $("input[name=minute]", fixture.el);
    const $meridian = $("input[name=meridian]", fixture.el);

    return this.subject = new DateTimeSelectionWidgetGroup(
      $date, $hour, $minute, $meridian
    );
  });

  describe("#getDateTime", function() {
    it("converts existing field values into the expected Date object", function() {
      return expect(this.subject.getDateTime()).toEqual(new Date(2015, 10, 13, 9, 15));
    });

    describe("when the date value is changed", function() {
      beforeEach(() => $("input[name=date]", fixture.el).val("3/2/2016"));

      return it("converts the new field values into the expected Date object", function() {
        return expect(this.subject.getDateTime()).toEqual(new Date(2016, 2, 2, 9, 15));
      });
    });

    describe("when the hour value is changed", function() {
      describe("3 AM", function() {
        beforeEach(function() {
          $("input[name=hour]", fixture.el).val(3);
          return $("input[name=meridian]", fixture.el).val("AM");
        });

        return it("converts the new field values into the expected Date object", function() {
          return expect(this.subject.getDateTime())
            .toEqual(new Date(2015, 10, 13, 3, 15));
        });
      });

      describe("4 PM", function() {
        beforeEach(function() {
          $("input[name=hour]", fixture.el).val(4);
          return $("input[name=meridian]", fixture.el).val("PM");
        });

        return it("converts the new field values into the expected Date object", function() {
          return expect(this.subject.getDateTime())
            .toEqual(new Date(2015, 10, 13, 16, 15));
        });
      });

      describe("midnight", function() {
        beforeEach(function() {
          $("input[name=hour]", fixture.el).val(12);
          return $("input[name=meridian]", fixture.el).val("AM");
        });

        return it("converts the new field values into the expected Date object", function() {
          return expect(this.subject.getDateTime())
            .toEqual(new Date(2015, 10, 13, 0, 15));
        });
      });

      return describe("noon", function() {
        beforeEach(function() {
          $("input[name=hour]", fixture.el).val(12);
          return $("input[name=meridian]", fixture.el).val("PM");
        });

        return it("converts the new field values into the expected Date object", function() {
          return expect(this.subject.getDateTime())
            .toEqual(new Date(2015, 10, 13, 12, 15));
        });
      });
    });

    return describe("when the minute value is changed", () => (() => {
      const result = [];
      for (var minute = 0; minute <= 59; minute += 15) {
        result.push(describe(`to ${minute}`, function() {
          beforeEach(() => $("input[name=minute]", fixture.el).val(minute));

          return it("converts the new field values into the expected Date object", function() {
            return expect(this.subject.getDateTime())
              .toEqual(new Date(2015, 10, 13, 9, minute));
          });
        }));
      }
      return result;
    })());
  });

  describe("#setDateTime", function() {
    describe("when the time is before noon", function() {
      beforeEach(function() { return this.subject.setDateTime(new Date(2016, 2, 2, 11, 45)); });

      it("sets itself to the expected Date object", function() {
        return expect(this.subject.getDateTime()).toEqual(new Date(2016, 2, 2, 11, 45));
      });

      it("sets the date field", () => expect($("input[name=date]", fixture.el).val()).toEqual("3/2/2016"));

      it("sets the hour field", () => expect($("input[name=hour]", fixture.el).val()).toEqual("11"));

      it("sets the minute field", () => expect($("input[name=minute]", fixture.el).val()).toEqual("45"));

      return it("sets the meridian field", () => expect($("input[name=meridian]", fixture.el).val()).toEqual("AM"));
    });

    describe("when the time is after noon", function() {
      beforeEach(function() { return this.subject.setDateTime(new Date(2016, 2, 2, 13, 45)); });

      it("sets itself to the expected Date object", function() {
        return expect(this.subject.getDateTime()).toEqual(new Date(2016, 2, 2, 13, 45));
      });

      it("sets the date field", () => expect($("input[name=date]", fixture.el).val()).toEqual("3/2/2016"));

      it("sets the hour field", () => expect($("input[name=hour]", fixture.el).val()).toEqual("1"));

      it("sets the minute field", () => expect($("input[name=minute]", fixture.el).val()).toEqual("45"));

      return it("sets the meridian field", () => expect($("input[name=meridian]", fixture.el).val()).toEqual("PM"));
    });

    describe("when the time is noon hour", function() {
      beforeEach(function() { return this.subject.setDateTime(new Date(2016, 2, 2, 12, 45)); });

      return it("sets itself to the right datetime", function() {
        expect($("input[name=date]", fixture.el).val()).toEqual("3/2/2016");
        expect($("input[name=hour]", fixture.el).val()).toEqual("12");
        return expect($("input[name=meridian]", fixture.el).val()).toEqual("PM");
      });
    });

    return describe("when the time is midnight hour", function() {
      beforeEach(function() { return this.subject.setDateTime(new Date(2016, 2, 2, 0, 45)); });

      return it("sets itself to the right datetime", function() {
        expect($("input[name=date]", fixture.el).val()).toEqual("3/2/2016");
        expect($("input[name=hour]", fixture.el).val()).toEqual("12");
        return expect($("input[name=meridian]", fixture.el).val()).toEqual("AM");
      });
    });
  });

  return xdescribe("#change", () => it("TODO: needs tests"));
});
