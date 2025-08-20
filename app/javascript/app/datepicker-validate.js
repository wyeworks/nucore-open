/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
// Activated by DatePickerData
window.DatePickerValidate = class DatePickerValidate {
  constructor(pickerSelector) {
    this.dateChanged = this.dateChanged.bind(this);
    this.$picker = $(pickerSelector);
  }

  activate() {
    if (!this.$picker.data("datepicker-validate-enabled")) {
      return this.$picker.on("change", this.dateChanged)
              .data("datepicker-validate-enabled", true);
    }
  }

  dateChanged(e) {
    const $input = $(e.target);

    const format = $input.datepicker("option", "dateFormat");
    const minDate = this._parseDate($input.datepicker("option", "minDate"), format);
    const maxDate = this._parseDate($input.datepicker("option", "maxDate"), format);

    try {
      const date = this._parseDate($input.val(), format);

      if (maxDate && (date > maxDate)) {
        throw new Error(`cannot be after ${this._formatDate(maxDate)}`);
      }
      if (minDate && (date < minDate)) {
        throw new Error(`cannot be before ${this._formatDate(minDate)}`);
      }

      $input.closest(".form-group").removeClass("has-error");
      return $input.siblings(".help-block").remove();
    } catch (error) {
      e = error;
      $input.closest(".form-group").addClass("has-error");
      return $input.after(`<span class='help-block'>${e.message}</span>`);
    }
  }

  _parseDate(dateOrString, format) {
    if (typeof dateOrString === "string") {
      try {
        return $.datepicker.parseDate(format, dateOrString);
      } catch (e) {
        throw new Error("invalid date format", e);
      }
    } else {
      return dateOrString;
    }
  }

  _formatDate(date) {
    return new TimeFormatter(date).dateString();
  }
};
