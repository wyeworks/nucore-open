/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
// Per https://www.tjvantoll.com/2012/06/15/detecting-print-requests-with-javascript/

this.PrintWarning = class PrintWarning {

  initListener() {
    if (!this.shouldWarn()) { return; }
    this.listen();
    return window.onbeforeprint = this.onPrintAction;
  }

  shouldWarn() { return $(".js--print-warning").length; }

  listen() {
    return this.mediaQuery().addListener(query => {
      if (!query.matches) { return; }
      return this.onPrintAction();
    });
  }

  mediaQuery() { return window.matchMedia("print"); }

  onPrintAction() {
    return alert(`This order is not submitted. \
Please click Save Submission and move to the next step before \
printing your sample sheet.`);
  }
};

$(() => new PrintWarning().initListener());
