$(document).ready(function() {
  opts = { eventDrop: handleEventDragDrop, eventResize: handleEventDragDrop, selectable: true, select: handleSelect }
  new FullCalendarConfig($("#calendar"), opts).init()

  init_datepickers();

  // initialize datepicker
  function init_datepickers() {
    if (typeof minDaysFromNow == "undefined") {
      window['minDaysFromNow'] = 0;
    }
    if (typeof maxDaysFromNow == "undefined") {
      window['maxDaysFromNow'] = 365;
    }
    $("#datepicker").datepicker({'minDate': minDaysFromNow, 'maxDate': maxDaysFromNow});

    $('.datepicker').each(function(){
      $(this).datepicker({'minDate': minDaysFromNow, 'maxDate': maxDaysFromNow})
      		.change(function() {
      			var d = new Date(Date.parse($(this).val()));
      			$('#calendar').fullCalendar('gotoDate', d);


      		});
    });
    // SPIKE
    $(".js--calendarForm").on("reservation:changed", function(evt, data) {
      renderCurrentEvent(data.start, data.end);
    }).trigger("reservation:force_updates");

    // SPIKE
  }

  function handleSelect(start, end, jsEvent, view, resource) {
    start = moment(start.format());
    end = moment(end.format());
    // renderCurrentEvent(start, end);
    $(".js--calendarForm").trigger("reservation:set_times", { start: start, end: end })
  }

  function handleEventDragDrop(event, delta, revertFunc) {
    // make sure we're in the browser's timezone
    start = moment(event.start.format());
    end = moment(event.end.format());
    $(".js--calendarForm").trigger("reservation:set_times", { start: start, end: end })
  }

  /* Copy in actual times from reservation time */
  function copyReservationTimeIntoActual(e) {
    e.preventDefault()
    $(this).fadeOut('fast');
    // copy each reserve_xxx field to actual_xxx
    $('[name^="reservation[reserve_"]').each(function() {
      var actual_name = this.name.replace(/reserve_(.*)$/, "actual_$1");
      $("[name='" + actual_name + "']").val($(this).val());
    });

    // duration_mins doesn't follow the same pattern, so do it separately
    var newval = $('[name="reservation[duration_mins]"]').val();

    $('[name="reservation[actual_duration_mins]_display"]').val(newval).trigger('change');
  }

  function setDateInPicker(picker, date) {
    var dateFormat = picker.datepicker('option', 'dateFormat');
    picker.val($.datepicker.formatDate(dateFormat, date));
  }
  function setTimeInPickers(id_prefix, date) {
    var hour = date.getHours() % 12;
    var ampm = date.getHours() < 12 ? 'AM' : 'PM';
    if (hour == 0) hour = 12;
    $('#' + id_prefix + '_hour').val(hour);
    $('#' + id_prefix + '_min').val(date.getMinutes());
    $('#' + id_prefix + '_meridian').val(ampm);
  }
  $('.copy_actual_from_reservation a').click(copyReservationTimeIntoActual);

  // BEGIN SPIKE
  function renderCurrentEvent(start, end) {
    if (window.currentEvent) {
      $("#calendar").fullCalendar("removeEvents", [window.currentEvent.id]);
    }
      window.currentEvent = {
        id: 124,
        title: "My Event",
        start: start,
        end: end,
        color: '#FF0000',
        allDay: false,
        editable: true
      };
     $("#calendar").fullCalendar('renderEvent', window.currentEvent, true);

    // END SPIKE
  }

});

