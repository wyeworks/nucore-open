/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
$.fn.animateHighlight = function(options) {
  if (options == null) { options = {}; }
  options = $.extend({}, {
      highlightClass: null,
      highlightColor: "#FFFF9C",
      solidDuration: 0,
      fadeDuration: 2500 }, options);
  if (options.highlightClass != null) {
    const new_item = $(`<div class='${options.highlightClass}'></div>`).hide().appendTo('body');
    options.highlightColor = new_item.css('backgroundColor');
    new_item.remove();
  }

  const originalBg = this.css("backgroundColor");
  return this.stop()
    .css("background-color", options.highlightColor)
    .delay(options.solidDuration)
    .animate({backgroundColor: originalBg}, options.fadeDuration);
};


class OrderDetailManagement {
  static initClass() {
    this.prototype.railsFormInputSelector = "[name=_method],[name=utf8],[name=authenticity_token]";
  }
  constructor($element) {
    this.$element = $element;
    this.$element.find('.datepicker').datepicker();
    this.$element.find('.timeinput').timeinput();
    this.$element.find('.copy_actual_from_reservation a').click(this.copyReservationTimeIntoActual);
    this.initTotalCalculating();
    this.initPriceUpdating();
    this.initReconcileNote();
    this.initCancelFeeOptions();
    this.initResolutionNote();
    this.initAccountOwnerUpdate();
    if (this.$element.hasClass('disabled')) { this.disableForm(); }
    this.$element.find(".js--order-detail-price-change-reason-select").on("change", function(event) {
      const selectedOption = event.target.options[event.target.selectedIndex];
      const noteTextField = $(".js--order-detail-price-change-reason");
      if (selectedOption.value === "Other") {
        return noteTextField.attr("hidden", false).val("");
      } else {
        noteTextField.attr("hidden", true);
        return noteTextField.val(selectedOption.value);
      }
    });
  }

  copyReservationTimeIntoActual(e) {
    e.preventDefault();
    $(this).fadeOut('fast');
    // copy each reserve_xxx field to actual_xxx
    $('[name^="order_detail[reservation][reserve_"]').each(function() {
      const actual_name = this.name.replace(/reserve_(.*)$/, "actual_$1");
      return $(`[name='${actual_name}']`).val($(this).val());
    });

    // duration_mins doesn't follow the same pattern, so do it separately
    const newval = $('[name="order_detail[reservation][duration_mins]"]').val();

    return $('[name="order_detail[reservation][actual_duration_mins]_display"]').val(newval).trigger('change');
  }

  initPriceUpdating() {
    // _display is excluded to prevent the displayed input for durations from
    // triggering. We want only the underlying quantity/mins input to trigger it.
    this.$element
      .find('.js--pricingUpdate input:not([name$=_display]),.js--pricingUpdate select')
      .bind("change keyup", evt => {
        if ($(evt.target).val().length > 0) { return this.updatePricing(evt); }
    });

    const repricingButton = document.querySelector(".js--recalculate-pricing");

    if (repricingButton) {
      repricingButton.addEventListener('click', () => { this.updatePricing() });
    }

    return this.$element.bind("reservation:times_changed", evt => {
      return this.updatePricing(evt);
    });
  }

  updatePricing(e) {
    const self = this;
    const url = this.$element.attr('action').replace('/manage', '/pricing');
    this.disableSubmit();

    return $.ajax({
      url,
      data: this.$element.serialize(),
      type: 'get',
      success(result, status) {
        // Update price group text
        self.$element.find('.subsidy .help-block').text(result['price_group']);
        const subsidy = result['actual_subsidy'] || result['estimated_subsidy'];
        self.$element.find('.subsidy input').prop('disabled', subsidy <= 0).css('backgroundColor', '');

        for (let field of ['cost', 'subsidy', 'total']) {
          const input_field = self.$element.find(`[name='order_detail[estimated_${field}]'],[name='order_detail[actual_${field}]']`);
          const old_val = input_field.val();
          const new_val = result[`actual_${field}`] || result[`estimated_${field}`];
          input_field.val(new_val);
          if (field === 'cost') {
            input_field.trigger('change');
            }
          if (old_val !== new_val) { input_field.animateHighlight(); }
        }
        return self.enableSubmit();
      }
    });
  }

  initTotalCalculating() {
    const self = this;
    return $('.cost-table .cost, .cost-table .subsidy').change(function() {
      // update total value
      const row = $(this).closest('.cost-table');
      const total = row.find('.cost input').val() - row.find('.subsidy input').val();
      row.find('.total input').val(total.toFixed(2));

      // update split table values
      self.updateSplitValues(total);

      // notify page of changes
      self.notifyOfUpdate($('.split-table'));
      return self.notifyOfUpdate($(row).find('input[name*=total]'));
    });
  }

  updateSplitValues(total) {
    const splitUpdateFields = $('.split-cost').toArray();
    const splitTotal = (percent) => Math.floor(total * percent) / 100;
    const reducer = (prev, splitField) => prev + splitTotal(splitField.dataset.percent);
    // Add up each split accounts' total
    const splitsTotalAmount = splitUpdateFields.reduce(reducer, 0);
    // Any remaining pennies are added to the "Apply Remainder" account.
    const remainder = total - splitsTotalAmount;

    splitUpdateFields.forEach(function(splitField) {
      var newSplitAmount = splitTotal(splitField.dataset.percent);
      if (splitField.dataset.applyRemainder === 'true' && remainder != 0) {
        newSplitAmount += remainder;
      }
      splitField.innerHTML = '$' + (newSplitAmount).toFixed(2);
    });
  }

  disableSubmit() {
    if (!this.waiting_requests) { this.waiting_requests = 0; }
    this.waiting_requests += 1;
    this.$element.find('.updating-message').removeClass('hidden');
    return this.$element.find('[type=submit]').prop('disabled', true);
  }

  enableSubmit() {
    this.waiting_requests -= 1;
    if (this.waiting_requests <= 0) {
      this.$element.find('.updating-message').addClass('hidden');
      this.$element.find('[type=submit]').prop('disabled', false);
    }
    if (this.$element.find(':focus').length === 0) {
      return this.$element.find('[type=submit]').focus();
    }
  }

  notifyOfUpdate(elem) {
    return elem.animateHighlight();
  }

  initCancelFeeOptions() {
    $('.cancel-fee-option').hide();
    const cancel_box = $('#with_cancel_fee');
    const cancel_id = parseInt(cancel_box.data('show-on'));
    return $(cancel_box.data('connect')).change(function() {
      return $('.cancel-fee-option').toggle(parseInt($(this).val()) === cancel_id);
    });
  }

  disableForm() {
    const obj = this;
    const form_elements = this.$element.find('select,textarea,input');
    form_elements.prop('disabled', function() {
      const leaveEnabled = $(this).hasClass('js-always-enabled') || $(this).is('[type=submit]') || obj.isRailsFormInput(this);
      return !leaveEnabled;
    });
    this.$element.find("select.js--chosen").trigger("chosen:updated");

    // remove the submit button if all form elements are disabled (and ignore
    // Rails hidden inputs)
    const any_enabled = form_elements.filter(':not([type=submit])')
      .filter(`:not(${this.railsFormInputSelector})`)
      .is(':not(:disabled)');
    if (!any_enabled) { return form_elements.filter('[type=submit]').remove(); }
  }

  initReconcileNote() {
    return $('#order_detail_order_status_id').change(function() {
      const reconciled = $(this).find('option:selected').text() === 'Reconciled';
      return $('.order_detail_reconciled_note').toggle(reconciled);}).trigger('change');
  }

  initResolutionNote() {
    const $modal_save_button = this.$element.find('input[type=submit]');
    const original_button_string = $modal_save_button.val();
    return $('#order_detail_dispute_resolved_reason').keyup(function() {
      if ($(this).val().length > 0) {
        $('#order_detail_resolve_dispute').val('1');
        return $modal_save_button.val('Resolve Dispute');
      } else {
        $('#order_detail_resolve_dispute').val('0');
        return $modal_save_button.val(original_button_string);
      }}).trigger('keyup');
  }

  initAccountOwnerUpdate() {
    return $('#order_detail_account_id').change(function() {
      const owner_name = $(this).find(':selected').data('account-owner');
      return $(this).closest('.control-group').find('.account-owner').text(owner_name);
    });
  }

  isRailsFormInput(input) {
    return $(input).is(this.railsFormInputSelector);
  }
}
OrderDetailManagement.initClass();

$(function() {
  const prepareForm = function() {
    const elem = $('form.manage_order_detail');

    if (elem.length > 0) { new OrderDetailManagement(elem); }
  };

  new AjaxModal('.manage-order-detail', '#order-detail-modal', {
    success: prepareForm
    });

  prepareForm();

  $('.updated-order-detail').animateHighlight({ highlightClass: 'alert-info', solidDuration: 5000 });

  return $('.timeinput').timeinput();
});

$(function() {
  new AjaxModal(".js--reportAnIssue", "#js--reportAnIssueModal");
});
