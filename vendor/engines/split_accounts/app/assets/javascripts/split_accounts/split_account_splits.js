/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
// Update the `percent` value in each visible `split` so the total of all splits
// adds up to 100.
const updateSplits = function(event, param) {
  switch (param.object_class) {
    case "split": case "split_accounts/split":
      var $container = $(event.target).closest("[data-subaccounts]");
      var $inputs = $container.find("[data-percent]").filter(":visible");

      if ($inputs.length > 0) {
        const percent = Math.round((100.0 / $inputs.length) * 100) / 100;
        const remainder = Math.round((100.0 - (percent * ($inputs.length - 1))) * 100) / 100;
        $inputs.val(percent);
        return $inputs.last().val(remainder);
      }
      break;
  }
};

// Register event listeners when nested_form_fields are added or removed
$(document).on("fields_added.nested_form_fields", updateSplits);
$(document).on("fields_removed.nested_form_fields", updateSplits);
