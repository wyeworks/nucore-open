/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
window.DateTimeSelectionWidgetGroup = class DateTimeSelectionWidgetGroup {
  constructor($dateField, $hourField, $minuteField, $meridianField) {
    this.valid = this.valid.bind(this);
    this.$dateField = $dateField;
    this.$hourField = $hourField;
    this.$minuteField = $minuteField;
    this.$meridianField = $meridianField;
  }

  getDateTime() {
    if (!this.$dateField.val() || !this.$hourField.val() || !this.$minuteField.val() || !this.$meridianField.val()) { return false; }
    const formatter = TimeFormatter.fromString(this.$dateField.val(), this.$hourField.val(), this.$minuteField.val(), this.$meridianField.val());
    return formatter.toDateTime();
  }

  setDateTime(dateTime) {
    const formatter = new TimeFormatter(dateTime);

    this.$dateField.val(formatter.dateString());
    this.$hourField.val(formatter.hour12());
    this.$meridianField.val(formatter.meridian());

    this.$minuteField.val(dateTime.getMinutes());

    return this.change();
  }

  valid() {
    return this.getDateTime() && !isNaN(this.getDateTime().getTime());
  }

  change(callback) {
    const fields = [this.$dateField, this.$hourField, this.$minuteField, this.$meridianField];
    return Array.from(fields).map(($field) => $field.change(callback));
  }

  static fromFields(form, date_field, hour_field, minute_field, meridian_field) {
    return new DateTimeSelectionWidgetGroup(
      $(form).find(`[name=\"${date_field}\"]`),
      $(form).find(`[name=\"${hour_field}\"]`),
      $(form).find(`[name=\"${minute_field}\"]`),
      $(form).find(`[name=\"${meridian_field}\"]`)
    );
  }
};

window.ReservationTimeFieldAdjustor = class ReservationTimeFieldAdjustor {
  constructor($form, opts, reserveInterval) {
    this.setTimes = this.setTimes.bind(this);
    this._durationChangeCallback = this._durationChangeCallback.bind(this);
    this._reserveEndChangeCallback = this._reserveEndChangeCallback.bind(this);
    this._reserveStartChangeCallback = this._reserveStartChangeCallback.bind(this);
    this._changed = this._changed.bind(this);
    this.$form = $form;
    this.opts = opts;
    if (reserveInterval == null) { reserveInterval = 1; }
    this.reserveInterval = reserveInterval;
    this.reserveStart = DateTimeSelectionWidgetGroup.fromFields(
      this.$form,
      ...Array.from(this.opts["start"])
    );

    this.reserveEnd = DateTimeSelectionWidgetGroup.fromFields(
      this.$form,
      ...Array.from(this.opts["end"])
    );

    this.durationFieldSelector = `[name=\"${this.opts["duration"]}\"]`;

    this.addListeners();
  }

  durationField() {
    return this.$form.find(this.durationFieldSelector);
  }

  addListeners() {
    this.reserveStart.change(this._reserveStartChangeCallback);
    this.reserveEnd.change(this._reserveEndChangeCallback);
    // Trying to bind directly to the element can cause timeing problems
    this.$form.on("change", this.durationFieldSelector, this._durationChangeCallback);
    this.$form.on("reservation:set_times", (evt, data) => {
      return this.setTimes(data.start, data.end);
    });
  }

  // in minutes
  calculateDuration() {
    return (this.reserveEnd.getDateTime() - this.reserveStart.getDateTime()) / 60 / 1000;
  }

  setTimes(start, end) {
    if (start) { this.reserveStart.setDateTime(start.toDate()); }
    if (end) {
      this.reserveEnd.setDateTime(end.toDate());
      return this._reserveEndChangeCallback(); // update duration
    } else {
      return this._durationChangeCallback();
    }
  }

  _durationChangeCallback() {
    const durationMinutes = this.durationField().val();
    if ((durationMinutes % this.reserveInterval) !== 0) { return; }

    if (this.reserveStart.valid()) {
      this.reserveEnd
        .setDateTime(this.reserveStart.getDateTime().addMinutes(durationMinutes));
    } else if (this.reserveEnd.valid()) { // If we had an end, but no begin
      this.reserveStart
        .setDateTime(this.reserveEnd.getDateTime().addMinutes(-durationMinutes));
    }

    return this._changed();
  }

  _reserveEndChangeCallback() {
    if (!this.reserveEnd.valid()) { return; }

    if (this.calculateDuration() < 0) {
      // If the duration ends up negative, i.e. end is before start,
      // set the end to the start time plus the duration specified in the box
      this.reserveEnd
        .setDateTime(this.reserveStart.getDateTime()
          .addMinutes(this.durationField().val()));
    }

    this.durationField().val(this.calculateDuration());
    this.durationField().trigger("change");
    return this._changed();
  }

  _reserveStartChangeCallback() {
    // Wait until all the fields are filled before we do anything here
    if (!this.reserveStart.valid()) { return; }

    const duration = this.durationField().val();
    // Duration starts as blank if there is a missing start/stop
    if (duration) {
      // Changing the start time will leave the duration alone, but change the
      // end time to X minutes after the start time
      const endTime = this.reserveStart.getDateTime().addMinutes(duration);
      this.reserveEnd.setDateTime(endTime);
    } else {

      if (this.calculateDuration() < 0) {
        // If the duration ends up negative, i.e. start is after end, leave the
        // start time alone, but set the end time to the beginning.
        this.reserveEnd.setDateTime(this.reserveStart.getDateTime());
      }

      this.durationField().val(this.calculateDuration());
      this.durationField().trigger("change");
    }

    return this._changed();
  }

  _changed() {
    return this.$form.trigger("reservation:times_changed", { start: this.reserveStart.getDateTime(), end: this.reserveEnd.getDateTime() });
  }
};

window.DailyReservationTimeFieldAdjustor = class DailyReservationTimeFieldAdjustor {
  constructor($form, opts) {
    this.form = $form;
    this.opts = opts;
    this.reserveStart = DateTimeSelectionWidgetGroup.fromFields(
      this.form,
      ...Array.from(this.opts["start"])
    );
    this.reserveEnd = DateTimeSelectionWidgetGroup.fromFields(
      this.form,
      ...Array.from(this.opts["end"])
    );
    this.duration = $(`[name=\"${this.opts["duration"]}\"]`);

    this.addListeners();
  }

  addListeners() {
    // Update reserve end date when duration or start date change
    this.duration.on('keyup', this.updateReserveEndDate.bind(this));
    this.reserveStart.$dateField.on('change', this.updateReserveEndDate.bind(this));

    // Copy start time to end time when changes
    function copyFieldValueCallback(targetEl) {
      return function(event) {
        $(targetEl).val($(event.target).val())
      }
    }
    this.reserveStart.$hourField.on(
      'change', copyFieldValueCallback(this.reserveEnd.$hourField)
    );
    this.reserveStart.$minuteField.on(
      'change', copyFieldValueCallback(this.reserveEnd.$minuteField)
    );
    this.reserveStart.$meridianField.on(
      'change', copyFieldValueCallback(this.reserveEnd.$meridianField)
    );

    // Trigger form changes when duration or end date changes
    this.reserveStart.change(this.triggerChange.bind(this));
    this.duration.on('keyup', this.triggerChange.bind(this));
    // this.reserveEnd.change(this.triggerChange.bind(this));

    // Trigger change when a change event is received
    this.form.on('reservation:set_times', this.triggerChange.bind(this));
  }

  /**
   * Update reservation_end_date out of duration days and start date
   */
  updateReserveEndDate() {
    let duration = parseInt(this.duration.val());
    let startDateEpoch = Date.parse(this.reserveStart.$dateField.val());

    if (!(duration > 0 && startDateEpoch > 0)) { return; }

    let startDate = new Date(startDateEpoch);
    let endDate = new Date(startDate);

    endDate.setDate(startDate.getDate() + duration);

    let dateFormat = this.reserveStart.$dateField.datepicker('option', 'dateFormat');
    let dateStr = $.datepicker.formatDate(dateFormat, endDate)

    this.reserveEnd.$dateField.val(dateStr);
  }

  /* Trigger change and passes start and end times */
  triggerChange() {
    this.form.trigger(
      "reservation:times_changed",
      {
        start: this.reserveStart.getDateTime(),
        end: this.reserveEnd.getDateTime()
      }
    );
  }
}

$(function() {
  $(".js--problemReservationForm").each((i, elem) => new ReservationTimeFieldAdjustor(
    $(elem), {
    "start": [
      "reservation[actual_start_date]",
      "reservation[actual_start_hour]",
      "reservation[actual_start_min]",
      "reservation[actual_start_meridian]"
    ],
    "end": [
      "reservation[actual_end_date]",
      "reservation[actual_end_hour]",
      "reservation[actual_end_min]",
      "reservation[actual_end_meridian]"
    ],
    "duration": "reservation[actual_duration_mins]"
  }
  ));
});
