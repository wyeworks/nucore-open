class window.DateTimeSelectionWidgetGroup
  constructor: (@$dateField, @$hourField, @$minuteField, @$meridianField, @reserveInterval) ->

  getDateTime: ->
    formatter = TimeFormatter.fromString(@$dateField.val(), @$hourField.val(), @$minuteField.val(), @$meridianField.val())
    formatter.toDateTime()

  setDateTime: (dateTime) ->
    formatter = new TimeFormatter(dateTime)

    @$dateField.val(formatter.dateString())
    @$hourField.val(formatter.hour12())
    @$meridianField.val(formatter.meridian())

    @$minuteField
      .val(dateTime.getMinutes() - (dateTime.getMinutes() % @reserveInterval))

    @change()

  change: (callback) ->
    fields = [@$dateField, @$hourField, @$minuteField, @$meridianField]
    $field.change(callback) for $field in fields

class window.ReservationTimeFieldAdjustor
  constructor: (@$form, @reserveInterval) ->
    @timeParser = new TimeParser() # From clockpunch
    @addListeners()

  addListeners: ->
    @reserveStart = @_widgetGroup('reserve_start')
    @reserveStart.change(@_reserveStartChangeCallback)

    @reserveEnd = @_widgetGroup('reserve_end')
    @reserveEnd.change(@_reserveEndChangeCallback)

    @$durationField = @$form.find('[name="reservation[duration_mins]"]')
    @$durationField.change(@_durationChangeCallback)

    @$durationDisplayField =
      @$form.find('[name="reservation[duration_mins]_display"]')

  _durationChangeCallback: =>
    durationMinutes = @timeParser.to_minutes(@$durationDisplayField.val())
    if durationMinutes % @reserveInterval == 0
      @reserveEnd
        .setDateTime(@reserveStart.getDateTime().addMinutes(durationMinutes))

  _getDuration: -> @reserveEnd.getDateTime() - @reserveStart.getDateTime()

  _minimumDuration: -> @reserveInterval * 60 * 1000

  _reserveEndChangeCallback: =>
    duration = @_getDuration()

    if duration < 0
      duration = @_minimumDuration()
      @reserveStart
        .setDateTime(@reserveEnd.getDateTime()
        .addMilliseconds(-1 * duration))
    @_setDurationFields(duration)

  _reserveStartChangeCallback: =>
    duration = @_getDuration()
    if duration < 0
      duration = @_minimumDuration()
      @reserveEnd
        .setDateTime(@reserveStart.getDateTime()
        .addMilliseconds(duration))
    @_setDurationFields(duration)

  _setDurationFields: (duration) ->
    durationMinutes = duration / 60000
    @$durationDisplayField
      .val(@timeParser.from_minutes(durationMinutes))
      .trigger("keyup")
    @$durationField.val(durationMinutes)

  _widgetGroup: (field) =>
    new DateTimeSelectionWidgetGroup(
      @$form.find("[name=\"reservation[#{field}_date]\"]")
      @$form.find("[name=\"reservation[#{field}_hour]\"]")
      @$form.find("[name=\"reservation[#{field}_min]\"]")
      @$form.find("[name=\"reservation[#{field}_meridian]\"]")
      @reserveInterval
    )

$ ->
  $("form.new_reservation, form.edit_reservation").each ->
    new ReservationTimeFieldAdjustor($(this), reserveInterval)
