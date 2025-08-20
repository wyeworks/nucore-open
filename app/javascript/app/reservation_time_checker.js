/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
// Validates that the selected reservation is valid for max/min durations as well
// as interval (5, 10, 15, 30 minutes).
window.ReservationTimeChecker = class ReservationTimeChecker {
  constructor(selector, alertId) {
    this.selector = selector;
    if (alertId == null) { alertId = 'duration-alert'; }
    this.alertId = alertId;
    if (this.validPage()) {
      this.initAlert();
      this.respondToChange();
    }
  }

  validPage() {
    // These variable are not set on the admin reservation pages
    return (typeof reserveInterval !== 'undefined' && reserveInterval !== null) && (typeof reserveMinimum !== 'undefined' && reserveMinimum !== null) && (typeof reserveMaximum !== 'undefined' && reserveMaximum !== null);
  }

  duration() {
    const parser = new TimeParser();
    return parser.to_minutes($(this.selector).val());
  }


  hasMinimumRestriction() { return reserveMinimum > 0; }


  hasMaximumRestriction() { return reserveMaximum > 0; }


  isViolatingInterval() { return (this.duration() % reserveInterval) !== 0; }


  isExceedingMaximum() { return this.hasMaximumRestriction() && (this.duration() > reserveMaximum); }


  isUnderMinimum() { return this.hasMinimumRestriction() && (this.duration() < reserveMinimum); }


  hasError() { return this.isViolatingInterval() || this.isExceedingMaximum() || this.isUnderMinimum(); }


  initAlert() { return $(this.selector).after(`<p id=\"${this.alertId}\" class=\"alert alert-danger hidden\"/>`); }


  setAlert(msg) { return $(`#${this.alertId}`).text(msg); }


  currentErrorMessage() {
    if (this.isExceedingMaximum()) { return `duration cannot exceed ${reserveMaximum} minutes`; }
    if (this.isUnderMinimum()) { return `duration must be at least ${reserveMinimum} minutes`; }
    if (this.isViolatingInterval()) { return `duration must be a multiple of ${reserveInterval}`; }
  }


  showError() {
    $(this.selector).addClass('interval-error');
    this.setAlert(this.currentErrorMessage());
    return $(`#${this.alertId}`).removeClass('hidden');
  }


  hideError() {
    $(`#${this.alertId}`).addClass('hidden');
    return $(this.selector).removeClass('interval-error');
  }


  respondToChange() {
    return $(this.selector).keyup(() => {
      if (this.hasError()) {
        return this.showError();
      } else {
        return this.hideError();
      }
    });
  }
};

$(function() {
  const target = ".js--reservationValidations #reservation_duration_mins, .edit_reservation #reservation_duration_mins";

  if ($(target).length) {
    return new ReservationTimeChecker(target);
  }
});
