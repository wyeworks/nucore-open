class Flash {
  static info(message, location_selector) {
    return this.flash('info', message, location_selector);
  }

  static notice(message, location_selector) {
    return this.flash('notice', message, location_selector);
  }

  static error(message, location_selector) {
    return this.flash('error', message, location_selector);
  }

  static flash(level, message, location_selector) {
    return new Flash(location_selector).flash(level, message);
  }

  constructor(location_selector) {
    this.location_selector = $(location_selector || "#js--flash");
  }

  flash(level, message) {
    // existing flashes
    this.location_selector.find(".alert").remove();

    const flash = $("<p></p>").text(message).addClass('alert').addClass(`alert-${level}`);
    return this.location_selector.append(flash);
  }
}

export { Flash };
