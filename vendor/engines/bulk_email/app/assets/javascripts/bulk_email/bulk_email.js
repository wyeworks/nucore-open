/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
window.BulkEmailSearchForm = class BulkEmailSearchForm {
  constructor($form) {
    this.$form = $form;
    this._initUserTypeChangeHandler();
    this._initDateRangeSelectionHandlers();
  }

  hideNonRestrictedProducts() {
    const user_types = this.selectedUserTypes();
    const required_selected = user_types.filter(['authorized_users', 'training_requested']);
    // if either authorized_users or training_requested is selected (and nothing else),
    // we should display only restricted products
    return (required_selected.length > 0) && (required_selected.length === user_types.length);
  }

  selectedUserTypes() { return this.$userTypeCheckboxes().filter(':checked').map(function() { return this.value; }); }

  dateRelevant() {
    const user_types = this.selectedUserTypes().toArray();
    return user_types.includes('customers') || user_types.includes('account_owners');
  }

  updateFormOptions() {
    this.disableDatepickerWhenIrrelevant();
    return this.toggleNonRestrictedProducts();
  }

  disableDatepickerWhenIrrelevant() {
    // Dates only apply for 'customers' and 'account owners', as those are joined through orders
    const isDateIrrelevant = !this.dateRelevant();
    return this.$form.find('#dates_between')
      .toggleClass('disabled', isDateIrrelevant)
      .find('input')
      .prop('disabled', isDateIrrelevant);
  }

  toggleNonRestrictedProducts() {
    // Hide non-restricted items when doing an authorized_users search
    const isHideNonRestrictedProducts = this.hideNonRestrictedProducts();
    this.$form.find('#products option[data-restricted=false]').each(function() {
      const $option = $(this);
      $option.prop('disabled', isHideNonRestrictedProducts);
      if (isHideNonRestrictedProducts) { return $option.prop('selected', false); }
    });

    return this.$form.find('#products').trigger('chosen:updated');
  }

  $userTypeCheckboxes() { return this.$form.find('.bulk_email_user_type'); }

  _initUserTypeChangeHandler() {
    return this.$userTypeCheckboxes()
      .change(() => this.updateFormOptions())
      .trigger('change');
  }

  _initDateRangeSelectionHandlers() {
    return $(".js--bulk-email-date-range-selector").click(function(event) {
      event.preventDefault();
      const $link = $(event.target);
      $('#bulk_email_start_date').val($link.data('startDate'));
      return $('#bulk_email_end_date').val($link.data('endDate'));
    });
  }
};

window.BulkEmailCreateForm = class BulkEmailCreateForm {
  constructor($form) {
    this.$form = $form;
    this._initFormatSetOnSubmit();
    this._initSubmitButtonToggle();
  }

  $recipientCheckboxes() { return this.$form.find('.js--bulk-email-recipient'); }
  $submitButtons() { return this.$form.find('.js--bulk-email-submit-button'); }

  toggleSubmitButtons() {
    if (this.$recipientCheckboxes().is(':checked')) {
      return this.$submitButtons().removeClass('disabled').prop('disabled', false);
    } else {
      return this.$submitButtons().addClass('disabled').prop('disabled', true);
    }
  }

  _initSubmitButtonToggle() {
    this.$form.find('.js--select_all').click(() => this.toggleSubmitButtons());
    return this.$recipientCheckboxes().change(() => this.toggleSubmitButtons()).trigger('change');
  }

  _initFormatSetOnSubmit() {
    return this.$submitButtons().click(event => {
      const $submitButton = $(event.target);
      return this.$form.find('#format').val($submitButton.data('format'));
    });
  }
};

$(function() {
  $('#bulk_email').each(function() { return new BulkEmailSearchForm($(this)); });
  return $('#bulk_email_create').each(function() { return new BulkEmailCreateForm($(this)); });
});
