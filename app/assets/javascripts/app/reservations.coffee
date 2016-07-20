$ ->
  target = '#new_reservation #reservation_duration_mins, .edit_reservation #reservation_duration_mins'

  if $(target).length
    new ReservationTimeChecker(target)

    if isBundle? && !isBundle && !ordering_on_behalf
      $('#new_reservation .datetime-block select, #new_reservation #reservation_reserve_start_date').change ->

        return if ctrlMechanism == 'manual'

        now = new Date()
        future = now.clone().addMinutes(5)
        date = $('#reservation_reserve_start_date').val()
        hour = $('#reservation_reserve_start_hour').val()
        hour = "0#{hour}" if hour < 10
        mins = $('#reservation_reserve_start_min').val()
        mins = "0#{mins}" if mins < 10
        meridian = $('#reservation_reserve_start_meridian').val()

        date_string = "#{date} #{hour}:#{mins}:00 #{meridian}"

        picked = new Date(date_string)

        # change reservation creation button based on Reservation
        text = if instrumentOnline && picked.between(now, future) then 'Create & Start' else 'Create'
        $('#reservation_submit').attr('value', text)

      .trigger('change')

  $logoutModal = $("#logout_modal")
  if $logoutModal.length > 0
    $logoutModal.modal("show")
    logoutLink = $logoutModal.find(".logout").attr("href")
    window.setTimeout((-> window.location.href = logoutLink), 60000)
