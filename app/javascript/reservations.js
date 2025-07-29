$(document).ready(function() {
  initDatepickers();

  function reservationInput(fieldName) {
    return $(`[name="reservation[${fieldName}]"]`);
  }

  let isDailyBooking = reservationInput('duration_days').length > 0;

  // initialize datepicker
  function initDatepickers() {
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
    var newval = reservationInput('duration_mins').val();

    $('[name="reservation[actual_duration_mins]_display"]').val(newval).trigger('change');
  }

  $('.copy_actual_from_reservation a').click(copyReservationTimeIntoActual);

  const reservationFormEl = $(".js--reservationForm");
  const formHandlerOpts = {
    "start": [
      "reservation[reserve_start_date]",
      "reservation[reserve_start_hour]",
      "reservation[reserve_start_min]",
      "reservation[reserve_start_meridian]"
    ],
    "end": [
      "reservation[reserve_end_date]",
      "reservation[reserve_end_hour]",
      "reservation[reserve_end_min]",
      "reservation[reserve_end_meridian]"
    ],
  };

  if (isDailyBooking) {
    new DailyReservationTimeFieldAdjustor(
      reservationFormEl,
      {
        ...formHandlerOpts,
        "duration": "reservation[duration_days]"
      }
    );
  } else if (typeof reserveInterval !== 'undefined') {
    new ReservationTimeFieldAdjustor(
      reservationFormEl,
      {
        ...formHandlerOpts,
        "duration": "reservation[duration_mins]"
      },
      reserveInterval,
    );
  }
  new ReservationCalendar().init($("#calendar"), reservationFormEl, isDailyBooking);
});

