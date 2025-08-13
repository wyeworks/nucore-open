/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
window.ChosenActivator = class ChosenActivator {
  static activate() {
    $(".js--chosen").not(".optional").chosen();
    return $(".js--chosen.optional").chosen({allow_single_deselect: true});
  }
};

$(function() {
  ChosenActivator.activate();

  return AjaxModal.on_show(() => // Give the browser just enough time to set the width of the select before
  // activating Chosen. Otherwise, it will sometimes appear as 0-width.
  setTimeout(ChosenActivator.activate, 100));
});

