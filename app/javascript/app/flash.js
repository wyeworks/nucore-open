/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * DS208: Avoid top-level this
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
var exports = exports != null ? exports : this;

const Cls = (exports.Flash = class Flash {
  static initClass() {
  
    this.info = (message, location_selector) => {
      if (location_selector == null) { location_selector = '#js--flash'; }
      return this.flash('info', message, location_selector);
    };
  }
  static notice(message, location_selector) {
    if (location_selector == null) { location_selector = '#js--flash'; }
    return this.flash('notice', message, location_selector);
  }

  static error(message, location_selector) {
    if (location_selector == null) { location_selector = '#js--flash'; }
    return this.flash('error', message, location_selector);
  }

  static flash(level, message, location_selector) {
    if (location_selector == null) { location_selector = '#js--flash'; }
    return new Flash(location_selector).flash(level, message);
  }

  constructor(location_selector) {
    this.location_selector = $(location_selector);
  }

  flash(level, message) {
    // existing flashes
    this.location_selector.find(".alert").remove();

    const flash = $("<p></p>").text(message).addClass('alert').addClass(`alert-${level}`);
    return this.location_selector.append(flash);
  }
});
Cls.initClass();
