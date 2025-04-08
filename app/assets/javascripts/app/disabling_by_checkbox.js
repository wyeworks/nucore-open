/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
$(() => $("[data-disables]").on("change", function() {
  const attribute_id = $(this).data("disables");
  const is_checked = $(this).is(":checked");
  $(attribute_id).find("input").prop("disabled", !is_checked);
  return $(attribute_id).toggle(is_checked);
}).trigger("change"));
