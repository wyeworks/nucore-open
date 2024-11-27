var ReservationCalendar = function() {}

ReservationCalendar.prototype = {
  init: function($calendar, $reservationForm, readOnly) {
    this.id = $reservationForm.data("reservation-id") || "new";
    this.$calendar = $calendar;
    this.$reservationForm = $reservationForm;

    self = this; // so our callbacks have access to this object

    const fullCalendarOptions = readOnly ? {} : {
      eventDrop: this._handleEventDragDrop,
      eventResize: this._handleEventDragDrop,
      dayClick: this._handleClick,
    };

    fullCalendarOptions.eventOverlap = false;

    new FullCalendarConfig($calendar, fullCalendarOptions).init();
    $calendar.on("calendar:rendered", this._removeSelfFromSource);
    this._addReservationFormListener();
  },

  renderCurrentEvent: function(start, end) {
    // It was easier to remove the old one and create a new one rather than update
    // it and get fullCalendar to re-render it.
    if (this.currentEvent) {
      this.$calendar.fullCalendar("removeEvents", [this.currentEvent.id]);
    }
    this.currentEvent = {
      id: "_currentEvent",
      title: "My Reservation",
      start: start,
      end: end,
      className: 'current-event',
      allDay: false,
      startEditable: this._isStartEditable(),
      durationEditable: true
    };
   this.$calendar.fullCalendar("renderEvent", this.currentEvent, true);
  },

  // Listen to the reservation form for when it has updated times so we can re-render
  // the event in the calendar. At page load, the form gets loaded first, so this
  // event was already triggered before the calendar is ready. The `trigger` here
  // will tell the form to retrigger the times_changed event now that we're ready
  // for it.
  _addReservationFormListener: function() {
    self = this;
    this.$reservationForm.on("reservation:times_changed", function(evt, data) {
      self.renderCurrentEvent(data.start, data.end);
    }).trigger("reservation:set_times", {});
  },

  // When in edit mode,this will remove the current reservation from the JSON
  // source so we can replace it with our currentEvent.
  _removeSelfFromSource: function() {
    self.$calendar.fullCalendar("removeEvents", [self.id]);
  },

  _handleEventDragDrop: function(event, delta, revertFunc) {
    data = {
      start: self._fixTimezone(event.start),
      end:  self._fixTimezone(event.end),
    }
    self.$reservationForm.trigger("reservation:set_times", data);
  },

  _handleClick: function(date, jsEvent, view, resourceObj) {
    data = { start: self._fixTimezone(date) };
    self.$reservationForm.trigger("reservation:set_times", data);
  },

  // Calendar's times are in "ambiguous" mode. Calling `toDate()` on them will treat
  // them as UTC, but we want them in the browser's timezone so we can update the form
  // correctly.
  _fixTimezone: function(date) {
    return moment(date.format());
  },

  // Start is not editable in Edit when the reservation has already begun, but is
  // editable if the reservation has not yet begun. Will always be editable in New.
  _isStartEditable: function() {
    return this.$calendar.data("start-editable");
  }

}
