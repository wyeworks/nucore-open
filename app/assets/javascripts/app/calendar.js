/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
window.FullCalendarConfig = class FullCalendarConfig {
  constructor($element, customOptions) {
    this.buildTooltip = this.buildTooltip.bind(this);
    this.$element = $element;
    if (customOptions == null) { customOptions = {}; }
    this.customOptions = customOptions;
  }

  init() {
    let options = $.extend(
      this.options(),
      this.customOptions,
      this.calendarDataConfig(),
    );
    return this.$element.fullCalendar(options);
  }

  options() {
    const options = this.baseOptions();
    if (window.minTime != null) {
      options.minTime = `${window.minTime}:00:00`;
    }
    if (window.maxTime != null) {
      options.maxTime = `${window.maxTime}:00:00`;
      options.height = (42 * (maxTime - minTime)) + 52;
    }
    if (window.initialDate) {
      options.defaultDate = window.initialDate;
    }
    return options;
  }

  baseOptions() {
    let self = this;

    return {
      editable: false,
      defaultView: "agendaWeek",
      allDaySlot: false,
      nextDayThreshold: '00:00:00',
      events: events_path,
      loading: (isLoading, _view) => {
        return this.toggleOverlay(isLoading);
      },
      eventAfterRender: function(event, element, view) {
        self.buildTooltip(event, element, view);
        self.adjustEvent(event, element, view);
      },
      eventAfterAllRender: view => {
        this.$element.trigger("calendar:rendered");
        return this.toggleNextPrev(view);
      }
    };
  }

  calendarDataConfig() {
    const ret = {};
    const allowedKeys = [
      "defaultView",
      "editable",
    ];

    let self = this;
    allowedKeys.forEach(function(key) {
      let value = self.$element.data(key)
      if (value) {
        ret[key] = value;
      }
    });

    return ret;
  }

  toggleOverlay(isLoading) {
    if (isLoading) {
      return $("#overlay").addClass("on").removeClass("off");
    } else {
      return $("#overlay").addClass("off").removeClass("on");
    }
  }

  toggleNextPrev(view) {
    try {
      const startDate = this.formatCalendarDate(view.start);
      const endDate = this.formatCalendarDate(view.end);

      $(".fc-button-prev").toggleClass("fc-state-disabled", startDate < window.minDate);
      return $(".fc-button-next").toggleClass("fc-state-disabled", endDate > window.maxDate);
    } catch (error) {}
  }

  buildTooltip(event, element) {
    // Default for our tooltip is to show, even if data-attribute is undefined.
    // Only hide if explicitly set to false.
    if ($("#calendar").data("show-tooltip") !== false) {
      const tooltip = [
        this.formattedEventPeriod(event),
        event.title,
        event.email,
        event.product,
        event.expiration,
        event.userNote,
        event.orderNote,
        this.linkToEditOrder(event)
      ].filter(
        e => // remove undefined values
        e != null).join("<br/>");

      // create the tooltip
      if (element.qtip) {
        return $(element).qtip({
          content: tooltip,
          style: {
            classes: "qtip-light"
          },
          position: {
            at: "bottom left",
            my: "topRight"
          },
          hide: {
            fixed: true,
            delay: 300
          }
        });
      }
    }
  }

  // window.minDate/maxDate are strings formatted like 20170714
  formatCalendarDate(date) {
    return $.fullCalendar.formatDate(date, "yyyyMMdd");
  }

  formattedEventPeriod(event) {
    let format = (this.isDailyBooking() && event.end.isAfter(event.start, 'day')) ? "MM/DD/YY h:mmA" : "h:mmA";

    return [event.start, event.end].
      map(date => $.fullCalendar.formatDate(date, format)).
      join(" &ndash; ");
  }

  linkToEditOrder(event) {
    if ((event.orderId != null) && (typeof orders_path_base !== 'undefined' && orders_path_base !== null)) { return `<a href='${orders_path_base}/${event.orderId}'>Edit</a>`; }
  }

  /*
   * Render monthly view events with margins
   * depending on the start and end offset
   * from midnight.
   *
   * It's called once for each event segment:
   * - Callback ref: https://fullcalendar.io/docs/v3/eventAfterRender
   * - Segment object: https://fullcalendar.io/docs/v3/eventLimitClick#event-segment-object
   */
  adjustEvent(event, element, view) {
    // Do nothing if not daily booking
    if (!this.isDailyBooking()) { return; }
    // Don't apply changes unless monthly view
    if (view.name != 'month') { return; }
    // exclude allDay and background events
    if (event['rendering'] == 'background' || event['allDay']) { return; }

    let seg = $(element).data('fc-seg');
    // if there's no info about the drawn event segment
    // there's nothing to do
    if (!seg) { return; }

    let startOfDay = event.start.clone();
    startOfDay.startOf('day');

    let endOfDay = event.end.clone();
    endOfDay.startOf('day');
    // If event end is the start of the day it's already
    // the follwoing day
    if (endOfDay.diff(event.end) != 0) {
      endOfDay.add(1, 'day')
    }

    let startOffset = event.start.diff(startOfDay, 'minutes');
    if (!seg.isStart) {
      // Event started some row above
      startOffset = 0;
    }
    let endOffset = endOfDay.diff(event.end, 'minutes');
    if (!seg.isEnd) {
      // Event ends some row below
      endOffset = 0;
    }

    let marginLeft = startOffset / 14.40; // 1440 minutes per day in percentage
    let marginRight = endOffset / 14.40;

    // Normalize margins relative to the amount of slots
    // in the segment
    let eventSegmentSlots = seg.rightCol - seg.leftCol + 1;
    marginLeft /= eventSegmentSlots;
    marginRight /= eventSegmentSlots;

    // Adjust margins to short hourly events that last less than a day
    // and use a single slot so there's enough width to read the text.
    let hourlyEvent = event.end.diff(event.start, 'hours') < 24;
    if (hourlyEvent && eventSegmentSlots == 1) {
      let minWidthPercent = 60;
      let eventWidth = 100 - marginLeft - marginRight;
      if (eventWidth < minWidthPercent) {
        // Reduce margins so minWidthPercent is reached
        let leftover = minWidthPercent - eventWidth;
        marginLeft -= leftover / 2;
        marginRight -= leftover / 2;
      }
      marginLeft = Math.max(0, marginLeft);
      marginRight = Math.max(0, marginRight);
    }

    $(element).css('margin-left', marginLeft + "%");
    $(element).css('margin-right', marginRight + "%");
  }

  isDailyBooking() {
    return typeof dailyBooking !== 'undefined' && dailyBooking;
  }
};
