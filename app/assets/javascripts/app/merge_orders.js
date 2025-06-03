/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
window.MergeOrder = class MergeOrder {
  constructor($form) {
    this.$form = $form;
  }
    // empty body

  initTimeBasedServices() {
    if (!this.$form.length) { return; }

    this.$quantity_field = this.$form.find(".js--edit-order__quantity");
    this.$duration_display_field = this.$form.find(".js--edit-order__duration");
    this.$duration_display_container = this.$form.find(
      ".js--edit-order__duration-container"
    );

    // clockpunch converts the original field into a field with name _display.
    // We will need to disable both the visible display field and the hidden field
    // so they don't get sent as part of the POST unless a timed service is
    // selected.
    this.$duration_display_field.timeinput();
    this.$duration_hidden_field = this.$duration_display_field.data("timeparser").$hidden_field;

    this.$form.find(".js--edit-order__product").on("change", event => {
      const is_timed = $(event.target).find(":selected").data("timed-product");

      this.$duration_display_field.toggle(is_timed);
      this.$duration_display_field.prop("disabled", !is_timed);
      this.$duration_hidden_field.prop("disabled", !is_timed);

      this.$duration_display_container.toggle(is_timed);

      if (is_timed) { this.$quantity_field.val(1); }
      return this.$quantity_field.prop("disabled", is_timed);
    });

    return this.$form.find(".js--edit-order__product").trigger("change");
  }

  initCrossCoreOrdering() {
    if (!this.$form.length) { return; }

    const productField = this.$form.find(".js--edit-order__product");
    const facilityField = this.$form.find(".js--edit-order__facility");
    const accountField = this.$form.find(".js--edit-order__account");
    const button = this.$form.find(".js--edit-order__button");

    if (!facilityField || !button) return;

    const originalFacilityId = button.data("original-facility");
    const defaultButtonText = button.data("default-button-text");
    const crossCoreButtonText = button.data("cross-core-button-text");

    const mergeOrders = this;

    return facilityField.on("change", (event) => {
      const selectedElement = $(event.target).find(":selected");
      const productsUrl = selectedElement.data("products-path");
      const accountsUrl = selectedElement.data("accounts-path");
      const originalOrderFacility = selectedElement.data("original-order-facility");
      const originalOrder = selectedElement.data("original-order");
      const facility_id = $(event.target).val();

      $.ajax({
        type: "get",
        data: { facility_id, original_facility: originalOrderFacility },
        url: productsUrl,
        success(data) {
          // Populate dropdown
          productField.empty();

          const rawIncludeBlank = productField.attr("include_blank")
          if (rawIncludeBlank && JSON.parse(rawIncludeBlank)) {
            productField.append('<option value=""></option>');
          }

          data = JSON.parse(data);
          data.forEach(function (product) {
            return productField.append(
              '<option value="' +
                product.id +
                '" data-timed-product="' +
                product.time_based +
                '">' +
                product.name +
                "</option>"
            );
          });

          mergeOrders.initTimeBasedServices()
          productField.trigger("chosen:updated");

          // Update button text
          const buttonText =
            originalFacilityId !== parseInt(facility_id)
              ? crossCoreButtonText
              : defaultButtonText;

          button.val(buttonText);

          return productField.trigger("change");
        },
      });

      return $.ajax({
        type: "get",
        data: { order_id: originalOrder },
        url: accountsUrl,
        success(data) {
          // Populate dropdown
          accountField.empty();
          data = JSON.parse(data);

          const rawIncludeBlank = accountField.attr("include_blank");
          if (rawIncludeBlank && JSON.parse(rawIncludeBlank)) {
            accountField.append('<option value=""></option>');
          }

          data.forEach(function (account) {
            return accountField.append(
              '<option value="' +
                account.id +
                '">' +
                account.label +
                "</option>"
            );
          });

          accountField.trigger("chosen:updated");

          return accountField.trigger("change");
        },
      });
    });
  }
};

$(function() {
  const mergeOrder = new MergeOrder($(".js--edit-order"));
  mergeOrder.initTimeBasedServices();
  return mergeOrder.initCrossCoreOrdering();
});
