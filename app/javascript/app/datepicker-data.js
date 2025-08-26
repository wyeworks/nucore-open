/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
window.DatePickerData = class DatePickerData {
  static activate() {
    // This will set up a datepicker based on data attributes
    // Make sure you call `to_s` or `iso8601` on any dates you set in the views
    // to ensure the proper format.
    const $pickers = $(".datepicker__data");

    $pickers.each(function(i, picker) {
      const $picker = $(picker);
      return $picker.datepicker({
        minDate: new Date($picker.data("min-date")), // will be unbounded if not provided
        maxDate: new Date($picker.data("max-date")) // will be unbounded if not provided
      });
    });

    return new DatePickerValidate($pickers).activate();
  }
};

$(function() {
  DatePickerData.activate();
  return AjaxModal.on_show(DatePickerData.activate);
});
