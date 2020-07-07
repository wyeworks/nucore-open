class TabbableReports
  constructor: (@$element) ->
    return unless @$element.length > 0
    @$tabs = @$element.find('#tabs')
    @init_tabs()
    @init_form()
    @init_pagination()
    @init_export_all_handler()

  export_all_link: ->
    $(".js--exportRaw")

  update_parameters: ->
    @update_href $(@current_tab())
    @refresh_tab()

  refresh_tab: ->
    index = @$tabs.tabs('option', 'active')
    current_tab = @$tabs.find('[role=tab]')[index]
    @$tabs.tabs('load', index)

  current_tab: ->
    index = @$tabs.tabs('option', 'active')
    current_tab = @$tabs.find('[role=tab]')[index]

  init_tabs: ->
    @$tabs.find('a').each (_, tab_link) ->
      $tab_link = $(tab_link)
      $tab_link.parent('li').data('base-href', $tab_link.attr('href'))

    @$tabs.tabs(
      active: window.activeTab
      beforeActivate: (_, ui) =>
        # if there was an old error message, fade it out now
        $('#error-msg').fadeOut()
        @update_href(ui.newTab)
        true

      beforeLoad: (_, ui) ->
        @in_flight_xhr.abort() if @in_flight_xhr?
        @in_flight_xhr = ui.jqXHR

        # Show a loading message so the user sees immediate feedback
        # that their action is being applied
        ui.panel.html('<span class="updating"></span> Loading...')
        ui.ajaxSettings.dataType = 'text/html'

        ui.jqXHR.always => @in_flight_xhr = null if @in_flight_xhr == ui.jqXHR

        ui.jqXHR.error (xhr, status, error) ->
          # don't show error message if the user aborted the ajax request
          if status != 'abort'
            $('#error-msg').
              html('Sorry, but the tab could not load. Please try again soon.').
              show()

      load: (_, ui) =>
        @update_export_all_link_visibility(ui.panel)
        @fix_bad_dates(ui.panel)
        @update_export_urls()
    )

  build_query_string: ->
    "?" + @$element.serialize()

  tab_url: (tab) ->
    $(tab).data('base-href') + @build_query_string()

  init_form: ->
    $('#status_filter').chosen() if $('#status_filter').length
    $('.datepicker').datepicker()
    @$element.find(':input').change => @update_parameters()

  update_href: (tab) ->
    tab.find('a').attr('href', @tab_url(tab))

  # Make sure to update the date params in case they were empty or invalid
  fix_bad_dates: (panel) ->
    $('#date_start').val($(panel).find('.updated_values .date_start').text())
    $('#date_end').val($(panel).find('.updated_values .date_end').text())

  init_pagination: ->
    $(document).on 'click', '.pagination a', (evt) =>
      evt.preventDefault()
      $(@current_tab()).find('a').attr('href', $(evt.target).attr('href'))
      @refresh_tab()

  update_export_all_link_visibility: (panel) ->
    if $(panel).find('.export_raw').data('visible')
      @export_all_link().show()
    else
      @export_all_link().hide()

  update_export_urls: ->
    url = @tab_url(@current_tab())
    $('#export').attr('href', url + '&export_id=report&format=csv')
    @export_all_link().attr("href", @export_all_link().data("original-url") + @build_query_string())

  init_export_all_handler: ->
    @$emailToAddressField = $('.js--exportRawEmailField')
    @export_all_link()
      .attr("data-remote", true)
      .data("original-url", @export_all_link().attr("href"))
      .click (event) => @export_all_email_confirm(event)

  export_all_email_confirm: (event) ->
    event.preventDefault()

    new_to = prompt(
      'Have the report emailed to this address:',
      @$emailToAddressField.val()
    )

    if new_to
      @$emailToAddressField.val(new_to)
      @update_export_urls()
      # Actual sending handled by remote: true
      Flash.info("A report is being prepared and will be emailed to #{new_to}
        when complete")
    else
      false # prevent handling by remote: true

$ ->
  window.report = new TabbableReports($('#refresh-form'))
