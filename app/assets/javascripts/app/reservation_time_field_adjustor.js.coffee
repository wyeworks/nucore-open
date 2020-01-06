class window.DateTimeSelectionWidgetGroup
  constructor: (@$dateField, @$hourField, @$minuteField, @$meridianField) ->

  getDateTime: ->
    return false unless @$dateField.val() && @$hourField.val() && @$minuteField.val() && @$meridianField.val()
    formatter = TimeFormatter.fromString(@$dateField.val(), @$hourField.val(), @$minuteField.val(), @$meridianField.val())
    formatter.toDateTime()

  setDateTime: (dateTime) ->
    formatter = new TimeFormatter(dateTime)

    @$dateField.val(formatter.dateString())
    @$hourField.val(formatter.hour12())
    @$meridianField.val(formatter.meridian())

    @$minuteField.val(dateTime.getMinutes())

    @change()

  valid: =>
    @getDateTime() && !isNaN(@getDateTime().getTime())

  change: (callback) ->
    fields = [@$dateField, @$hourField, @$minuteField, @$meridianField]
    $field.change(callback) for $field in fields

  @fromFields: (form, date_field, hour_field, minute_field, meridian_field) ->
    new DateTimeSelectionWidgetGroup(
      $(form).find("[name=\"#{date_field}\"]")
      $(form).find("[name=\"#{hour_field}\"]")
      $(form).find("[name=\"#{minute_field}\"]")
      $(form).find("[name=\"#{meridian_field}\"]")
    )

class window.ReservationTimeFieldAdjustor
  constructor: (@$form, @opts, @reserveInterval = 1) ->
    @reserveStart = DateTimeSelectionWidgetGroup.fromFields(
      @$form,
      @opts["start"]...,
    )

    @reserveEnd = DateTimeSelectionWidgetGroup.fromFields(
      @$form,
      @opts["end"]...,
    )

    @durationFieldSelector = "[name=\"#{@opts["duration"]}\"]"

    @addListeners()

  durationField: ->
    @$form.find(@durationFieldSelector)

  addListeners: ->
    @reserveStart.change(@_reserveStartChangeCallback)
    @reserveEnd.change(@_reserveEndChangeCallback)
    # Trying to bind directly to the element can cause timeing problems
    @$form.on "change", @durationFieldSelector, @_durationChangeCallback
    @$form.on "reservation:set_times", (evt, data) =>
      @setTimes(data.start, data.end)

  # in minutes
  calculateDuration: ->
    (@reserveEnd.getDateTime() - @reserveStart.getDateTime()) / 60 / 1000

  setTimes: (start, end) =>
    @reserveStart.setDateTime(start.toDate()) if start
    if end
      @reserveEnd.setDateTime(end.toDate())
      @_reserveEndChangeCallback() # update duration
    else
      @_durationChangeCallback()

  _durationChangeCallback: =>
    durationMinutes = @durationField().val()
    return unless durationMinutes % @reserveInterval == 0

    if @reserveStart.valid()
      @reserveEnd
        .setDateTime(@reserveStart.getDateTime().addMinutes(durationMinutes))
    else if @reserveEnd.valid() # If we had an end, but no begin
      @reserveStart
        .setDateTime(@reserveEnd.getDateTime().addMinutes(-durationMinutes))

    @_changed()

  _reserveEndChangeCallback: =>
    return unless @reserveEnd.valid()

    if @calculateDuration() < 0
      # If the duration ends up negative, i.e. end is before start,
      # set the end to the start time plus the duration specified in the box
      @reserveEnd
        .setDateTime(@reserveStart.getDateTime()
          .addMinutes(@durationField().val()))

    @durationField().val(@calculateDuration())
    @durationField().trigger("change")
    @_changed()

  _reserveStartChangeCallback: =>
    # Wait until all the fields are filled before we do anything here
    return unless @reserveStart.valid()

    duration = @durationField().val()
    # Duration starts as blank if there is a missing start/stop
    if duration
      # Changing the start time will leave the duration alone, but change the
      # end time to X minutes after the start time
      endTime = @reserveStart.getDateTime().addMinutes(duration)
      @reserveEnd.setDateTime(endTime)
    else

      if @calculateDuration() < 0
        # If the duration ends up negative, i.e. start is after end, leave the
        # start time alone, but set the end time to the beginning.
        @reserveEnd.setDateTime(@reserveStart.getDateTime())

      @durationField().val(@calculateDuration())
      @durationField().trigger("change")

    @_changed()

  _changed: =>
    @$form.trigger("reservation:times_changed", { start: @reserveStart.getDateTime(), end: @reserveEnd.getDateTime() })

$ ->
  # reserveInterval is not set on admin reservation pages, and we don't need these handlers there
  if reserveInterval?
    $(".js--reservationForm").each (i, elem) ->
      new ReservationTimeFieldAdjustor(
        $(elem),
        "start": [
          "reservation[reserve_start_date]",
          "reservation[reserve_start_hour]",
          "reservation[reserve_start_min]",
          "reservation[reserve_start_meridian]"
        ]
        "end": [
          "reservation[reserve_end_date]",
          "reservation[reserve_end_hour]",
          "reservation[reserve_end_min]",
          "reservation[reserve_end_meridian]"
        ]
        "duration": "reservation[duration_mins]"
      reserveInterval)
  $(".js--problemReservationForm").each (i, elem) ->
    new ReservationTimeFieldAdjustor(
      $(elem),
      "start": [
        "reservation[actual_start_date]",
        "reservation[actual_start_hour]",
        "reservation[actual_start_min]",
        "reservation[actual_start_meridian]"
      ]
      "end": [
        "reservation[actual_end_date]",
        "reservation[actual_end_hour]",
        "reservation[actual_end_min]",
        "reservation[actual_end_meridian]"
      ]
      "duration": "reservation[actual_duration_mins]"
    )
