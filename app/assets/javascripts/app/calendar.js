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
    var self = this;

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
    return [event.start, event.end].
      map(date => $.fullCalendar.formatDate(date, "h:mmA")).
      join("&ndash;");
  }

  linkToEditOrder(event) {
    if ((event.orderId != null) && (typeof orders_path_base !== 'undefined' && orders_path_base !== null)) { return `<a href='${orders_path_base}/${event.orderId}'>Edit</a>`; }
  }

  /*
   * Render monthly view events with margins
   * depending on the start and end offset
   * from midnight.
   */
  adjustEvent(event, element, view) {
    // Don't apply changes unless monthly view
    if (view.name != 'month') { return; }
    // exclude allDay and background events
    if (event['rendering'] == 'background' || event['allDay']) { return; }

    let seg = $(element).data('fc-seg');
    // if there's no info about the drawn event segment
    // there's nothing to do
    if (!seg) { return; }

    // Don't add margins if event last less than a day
    if (event.end.diff(event.start, 'days', true) < 1.0) { return; }

    let startOfDay = event.start.clone();
    startOfDay.startOf('day');
    let endOfDay = event.end.clone();
    endOfDay.endOf('day');

    let startOffsetDiff = event.start.diff(startOfDay, 'minutes');
    let startOffset = startOffsetDiff;
    if (!seg.isStart) {
      // Event started some row above
      startOffset = 0;
    }
    let endOffset = endOfDay.diff(event.end, 'minutes');
    // If startOffsetDiff is zero then reservation starts
    // at begging of thay and it does not have end offset
    if (!seg.isEnd || startOffsetDiff === 0) {
      // Event ends some row below
      endOffset = 0;
    }

    let marginLeft = startOffset / 14.40; // 1440 minutes per day in percentage
    let marginRight = endOffset / 14.40;

    let eventSegmentSlots = seg.rightCol - seg.leftCol + 1;

    // A maximum of 7 days (calendar slots) in each row
    marginLeft /= eventSegmentSlots;
    marginRight /= eventSegmentSlots;

    $(element).css('margin-left', marginLeft + "%");
    $(element).css('margin-right', marginRight + "%");
  }
};
