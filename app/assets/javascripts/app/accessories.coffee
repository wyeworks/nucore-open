class window.AccessoryPicker
  constructor: (@$form) ->
    @init_timeinput()
    @init_checkboxes()

  init_timeinput: ->
    @$form.find('.timeinput').timeinput()

  init_checkboxes: ->
    self = this
    @$form.find('input[type=checkbox]').change ->
      self.enable_elements(this)
    .trigger('change')

  enable_elements: (checkbox) ->
    $checkbox = $(checkbox)
    enabled = $checkbox.prop('checked')
    $row = $checkbox.closest('.accessory-row')

    $row.toggleClass('disabled', !enabled)
    $input = $row.find('input').not(checkbox).not('[type=hidden]')
    $input.prop('disabled', !enabled || $input.data('always-disabled') == true)
    # use visibility instead of show/hide so it maintains the same spacing
    $input.css('visibility', if enabled then 'visible' else 'hidden')

class AccessoryPickerDialog
  constructor: (@$link) ->
    @hide_tooltips()
    @init_dialog_element()
    @show_dialog()
    @fade_out()

  hide_tooltips: ->
    $('.tip').data('tooltipsy').hide() if $('.tip').length > 0

  init_dialog_element: ->
    self = this

    @dialog = $('#pick_accessories_dialog')

    # build dialog if necessary
    if @dialog.length == 0
      @dialog = $('<div id="pick_accessories_dialog" class="modal hide fade" data-backdrop="static" role="dialog"/>')
      @dialog.hide()
      $("body").append(@dialog);

    @dialog.on 'ajax:complete', 'form', (evt, xhr, status) ->
      self.handle_response(evt, xhr, status)

    if @$link.data('refresh-on-cancel')
      @dialog.on 'hidden', ->
        window.location.reload()

    @dialog.on 'submit', 'form', ->
      self.toggle_buttons(false)

  show_dialog: ->
    self = this
    $.ajax {
      url: @$link.attr('href')
      dataType: 'html'
      success: (body) ->
        self.load_dialog body
    }

  load_dialog: (body) =>
    @dialog.html(body).modal('show')
    @picker = new AccessoryPicker($('#accessory-form'))
    @toggle_buttons true

  toggle_buttons: (value) ->
    @dialog.find('input[type=submit]').prop('disabled', !value)

  handle_response: (e, xhr, status) ->
    e.preventDefault();
    if status == 'success'
      @dialog.modal('hide')
      window.location.reload()
    else
      @load_dialog(xhr.responseText)


  fade_out: ->
    @$link.fadeOut() unless @$link.hasClass('persistent')


$ ->
  $('body').on 'click', '.has_accessories', (evt) ->
    evt.preventDefault()
    picker = new AccessoryPickerDialog($(this))

  new AccessoryPicker($('.not-in-modal #accessory-form'))
