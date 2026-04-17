/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
window.ChosenActivator = class ChosenActivator {
  static activateChosen(elem, options = null) {
    elem = $(elem);

    options = {...options }
    if (elem.hasClass("chosen-full-width")) {
      options.width = "100%";
    }
    elem.chosen(options);
  }

  static activate() {
    $(".js--chosen").not(".optional").each(function() { ChosenActivator.activateChosen(this) })

    return $(".js--chosen.optional").each(function() {
      ChosenActivator.activateChosen(this, {allow_single_deselect: true})
    });
  }
};

$(function() {
  ChosenActivator.activate();

  return AjaxModal.on_show(() => // Give the browser just enough time to set the width of the select before
  // activating Chosen. Otherwise, it will sometimes appear as 0-width.
  setTimeout(ChosenActivator.activate, 100));
});

