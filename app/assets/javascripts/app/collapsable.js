/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
$(() => $("fieldset.collapsable").each(function() {
  const $this = $(this);
  $this.find("> :not(.legend)").toggle(!$this.hasClass("collapsed"));
  $this.enableDisableFields = function() {
    return this.find("input, select").prop('disabled', $this.hasClass('collapsed'));
  };

  $this.enableDisableFields();
  return $this.find(".legend").click(function() {
    // $this is still the fieldset, but 'this' is legend
    $this.toggleClass("collapsed").find("> :not(.legend)").slideToggle();
    return $this.enableDisableFields();
  });
}));
