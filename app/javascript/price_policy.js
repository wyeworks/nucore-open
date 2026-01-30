/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
$(document).ready(function() {

  const isFiniteAndPositive = number => isFinite(number) && (number > 0);

  // In addition to disabling the field, also hide its value. But still store it
  // so we can display it again if it gets renabled
  const hardToggleField = function($inputElement, isDisabled) {
    if ($inputElement.val()) { $inputElement.data("original-value", $inputElement.val()); }
    $inputElement.val(isDisabled ? "" : $inputElement.data("original-value"));
    return $inputElement.prop("disabled", isDisabled);
  };

  // Triggered by "Can purchase?"
  const toggleFieldsInSameRow = function($checkbox) {
    const $cells = $checkbox.parents("tr").find("td");
    const isDisabled = !$checkbox.prop("checked");
    $cells.toggleClass("disabled", isDisabled);
    $cells.find("input[type=text], input[type=hidden], input[type=checkbox]").not($checkbox).each((_i, elem) => hardToggleField($(elem), isDisabled));
    $cells.find(".per-minute").toggleClass("hidden", isDisabled);
    // If we are enabling the row, make sure the cancellation cost field gets the correct state
    if (!isDisabled) { return $cells.find(".js--fullCancellationCost").trigger("change"); }
  };

  const updateAdjustmentFields = function($sourceElement) {
    let rate = parseFloat($sourceElement.val());
    rate = isFiniteAndPositive(rate) ? rate : 0;

    const $targets = $(".js--adjustmentRow").find($sourceElement.data("target"));
    $targets.filter(":input").val(rate);
    return $targets.filter("span").html(rate);
  };

  const toggleFullCancellationCostInCurrentCell = function($checkbox) {
    const $container = $checkbox.parents(".js--cancellationCostContainer");
    return hardToggleField($container.find("input[type=text]"), $checkbox.is(":checked"));
  };

  const toggleFullCancellationInAdjustmentRows = function(isChecked) {
    const $adjustmentFields = $(".js--adjustmentRow .js--fullCancellationCost");
    $adjustmentFields.val(isChecked ? "1" : "0");
    hardToggleField($adjustmentFields.siblings(".js--cancellationCost").filter(":input"), isChecked);
    // Show/hide the pricing spans
    return $adjustmentFields.siblings(".js--cancellationCost").filter("span").toggle(!isChecked);
  };

  $(".js--canPurchase").change(evt => toggleFieldsInSameRow($(evt.target))).trigger("change");

  $(".js--fullCancellationCost").change(function(evt) {
    const $elem = $(evt.target);
    toggleFullCancellationCostInCurrentCell($elem);
    if ($elem.parents(".js--masterInternalRow").length) {
      toggleFullCancellationInAdjustmentRows($elem.is(":checked"));
      // Update trigger the adjustment rows to be updated off of the value
      if (!$elem.is(":checked")) { return $elem.parents(".js--cancellationCostContainer").find(".js--cancellationCost").trigger("keyup"); }
    }
  }).trigger("change");

  $(".js--masterInternalRow input[type=text]").keyup(evt => updateAdjustmentFields($(evt.target))).trigger("keyup");

  // Update external subsidy rows when parent external rate changes
  const updateExternalSubsidyRates = function($sourceElement) {
    const priceGroupId = $sourceElement.data("price-group-id");
    if (!priceGroupId) return;

    const rate = $sourceElement.val();
    $(`.js--externalSubsidyRow[data-parent-price-group-id="${priceGroupId}"]`).each(function() {
      $(this).find(".js--usageRate").val(rate);
    });
  };

  $(".usage_rate").on("keyup change", function(evt) {
    updateExternalSubsidyRates($(evt.target));
  }).trigger("keyup");

  $(".js--price-policy-note-select").on("change", function(event) {
    const selectedOption = event.target.options[event.target.selectedIndex];
    const noteTextField = $(".js--price-policy-note");
    if (selectedOption.value === "Other") {
      return noteTextField.attr("hidden", false).val("");
    } else {
      noteTextField.attr("hidden", true);
      return noteTextField.val(selectedOption.value);
    }
  });

  $(".js--baseRate").each(function (_index, element) {
    setRateForSubsidyPrieGroups(element);
  });

  $(".js--baseRate").on("change", function (event) {
    setRateForSubsidyPrieGroups(event.target)
  });

  function setRateForSubsidyPrieGroups(params) {
    const columnIndex = params.dataset.index;
    const stepBaseRate = params.value;
    $(
      `input[name*='duration_rates_attributes][${columnIndex}][rate]'].js--hiddenRate`
    ).val(stepBaseRate);
  }

  $(".js--minDuration").on("change", function (event) {
    setMinDurationHours(event.target)
    preventDuplicateMinDurations()
  });

  $(".js--minDuration").each(function (index, element) {
    setMinDurationHours(element)
  });

  function setMinDurationHours(params) {
    const columnIndex = params.dataset.index;
    const minDuration = params.value;
    $(`input[name*='duration_rates_attributes][${columnIndex}][min_duration_hours]']`).val(minDuration);
  }

  function preventDuplicateMinDurations(params) {
    var counts = {}
    var duplicates = $(".js--minDuration").each(function (_, el) {
      var value = el.value
      // var minDurationValue = $(ele).val();
      counts[value] = (counts[value] || 0) + 1
    }).filter(function (_, el) {
      return counts[el.value] > 1 && el.value !== ""
    })

    // reset error states
    $(".js--minDuration").each(function (i, element) {
      $(element).parent().removeClass("error");
    })

    if (duplicates.length > 0) {
      // set error state duplicate values
      duplicates.each(function (i, element) {
        $(element).parent().addClass("error");
      })
      // disable submit button
      $("input[type=submit]").prop("disabled", true);
      $("form").on("submit", function (e) { e.preventDefault(); });
    } else {
      // enable submit button
      $("input[type=submit]").prop("disabled", false);
      $("form").off("submit");
    }
  }
});
