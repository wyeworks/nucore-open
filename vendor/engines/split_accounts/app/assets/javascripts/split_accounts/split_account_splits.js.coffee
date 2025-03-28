# Update the `percent` value in each visible `split` so the total of all splits
# adds up to 100.
updateSplits = (event, param) ->
  switch param.object_class
    when "split", "split_accounts/split"
      $container = $(event.target).closest("[data-subaccounts]")
      $inputs = $container.find("[data-percent]").filter(":visible")

      if $inputs.length > 0
        percent = Math.round((100.0 / $inputs.length) * 100) / 100
        remainder = Math.round((100.0 - percent * ($inputs.length - 1)) * 100) / 100
        $inputs.val(percent)
        $inputs.last().val(remainder)

# Register event listeners when nested_form_fields are added or removed
$(document).on "fields_added.nested_form_fields", updateSplits
$(document).on "fields_removed.nested_form_fields", updateSplits
