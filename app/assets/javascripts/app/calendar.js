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
    return {
      editable: false,
      defaultView: "agendaWeek",
      allDaySlot: false,
      events: events_path,
      loading: (isLoading, view) => {
        return this.toggleOverlay(isLoading);
      },

      eventAfterRender: this.buildTooltip,
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
};
