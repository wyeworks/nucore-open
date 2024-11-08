$(document).ready(function() {
  init_datepickers();

  function reservationInput(fieldName) {
    return $(`[name="reservation[${fieldName}]"]`);
  }

  let form = {
    isDailyBooking: reservationInput('duration_days').length > 0,
    durationDaysEl: reservationInput('duration_days'),
    startDateEl: reservationInput('reserve_start_date'),
    endDateEl: reservationInput('reserve_end_date'),
    startHourEl: reservationInput('reserve_start_hour'),
    startMinEl: reservationInput('reserve_start_min'),
    startMeridianEl: reservationInput('reserve_start_meridian'),
    endHourEl: reservationInput('reserve_end_hour'),
    endMinEl: reservationInput('reserve_end_min'),
    endMeridianEl: reservationInput('reserve_end_meridian'),
  };

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

  /**
   * Update reservation_end_date out of duration days and start date
   */
  function updateReserveEndDate() {
    let duration = parseInt(form.durationDaysEl.val());
    let startDateEpoch = Date.parse(form.startDateEl.val());

    if (!(duration > 0 && startDateEpoch > 0)) { return; }

    let startDate = new Date(startDateEpoch);
    let endDate = new Date(startDate);

    endDate.setDate(startDate.getDate() + duration);

    let dateFormat = form.startDateEl.datepicker('option', 'dateFormat');
    let dateStr = $.datepicker.formatDate(dateFormat, endDate)

    form.endDateEl.val(dateStr);
  }

  function copyFieldValueCallback(targetEl) {
    return function(event) {
      $(targetEl).val($(event.target).val())
    }
  }

  $('.copy_actual_from_reservation a').click(copyReservationTimeIntoActual);

  if (form.isDailyBooking) {
    form.durationDaysEl.on('keyup', updateReserveEndDate);
    form.startDateEl.on('change', updateReserveEndDate);
    // Copy start time to end time when changes
    form.startHourEl.on('change', copyFieldValueCallback(form.endHourEl));
    form.startMinEl.on('change', copyFieldValueCallback(form.endMinEl));
    form.startMeridianEl.on('change', copyFieldValueCallback(form.endMeridianEl));
  }
  new ReservationCalendar().init($("#calendar"), $(".js--reservationForm"));
});

