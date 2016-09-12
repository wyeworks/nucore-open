class window.BulkEmailSearchForm
  constructor: (@$form) ->
    @_initUserTypeChangeHandler()

  authorizedUsersSelectedOnly: ->
    user_types = @selectedUserTypes()
    user_types.length == 1 && user_types[0] == 'authorized_users'

  selectedUserTypes: -> @$userTypeCheckboxes().filter(':checked').map -> @.value

  toggleNonRestrictedProducts: ->
    # Hide non-restricted items when doing an authorized_users search
    isHideNonRestrictedProducts = @authorizedUsersSelectedOnly()
    @$form.find('#products option[data-restricted=false]').each ->
      $option = $(this)
      $option.prop('disabled', isHideNonRestrictedProducts)
      $option.prop('selected', false) if isHideNonRestrictedProducts

    @$form.find('#products').trigger('chosen:updated')

    # Dates do not apply for authorized users search
    @$form.find('#dates_between')
      .toggleClass('disabled', isHideNonRestrictedProducts)
      .find('input')
      .prop('disabled', isHideNonRestrictedProducts)

  $userTypeCheckboxes: -> @$form.find('.bulk_email_user_type')

  _initUserTypeChangeHandler: ->
    @$userTypeCheckboxes()
      .change(=> @toggleNonRestrictedProducts())
      .trigger('change')

class window.BulkEmailCreateForm
  constructor: (@$form) ->
    @_initFormatSetOnSubmit()
    @_initSubmitButtonToggle()

  $recipientCheckboxes: -> @$form.find('.js--bulk-email-recipient')
  $submitButtons: -> @$form.find('.js--bulk-email-submit-button')

  toggleSubmitButtons: ->
    if @$recipientCheckboxes().is(':checked')
      @$submitButtons().removeClass('disabled').prop('disabled', false)
    else
      @$submitButtons().addClass('disabled').prop('disabled', true)

  _initSubmitButtonToggle: ->
    @$form.find('.js--select_all').click => @toggleSubmitButtons()
    @$recipientCheckboxes().change(=> @toggleSubmitButtons()).trigger('change')

  _initFormatSetOnSubmit: ->
    @$submitButtons().click (event) =>
      $submitButton = $(event.target)
      @$form.find('#format').val($submitButton.data('format'))

$ ->
  $('#bulk_email').each -> new BulkEmailSearchForm($(this))
  $('#bulk_email_create').each -> new BulkEmailCreateForm($(this))
