/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
window.SetFulfilledOnComplete = class SetFulfilledOnComplete {
  constructor($fulfilled_at) {
    this.$fulfilled_at = $fulfilled_at;
    if (this.$fulfilled_at.data("complete-target-init")) { return; }

    this.$select = $(this.$fulfilled_at.data("complete-target"));
    this.initializeListener();
    this.$select.change();
    this.$fulfilled_at.data("complete-target-init", true);
  }

  initializeListener() {
    return this.$select.change(event => {
      if ($(event.target).find("option:selected").text() === "Complete") {
        return this.$fulfilled_at.show();
      } else {
        return this.$fulfilled_at.hide();
      }
    });
  }

  static activate() {
    return $(".js--showOnCompleteStatus").each((_, select) => new SetFulfilledOnComplete($(select)));
  }
};

$(function() {
  SetFulfilledOnComplete.activate();
  return AjaxModal.on_show(SetFulfilledOnComplete.activate);
});
