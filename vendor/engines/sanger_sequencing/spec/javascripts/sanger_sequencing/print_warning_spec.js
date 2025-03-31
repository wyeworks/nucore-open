/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
//= require sanger_sequencing/print_warning
//= require helpers/jasmine-jquery

describe("Print Warning", function() {

  it("does nothing without the right thing in place", function() {
    const warning = new PrintWarning;
    spyOn(warning, "listen");
    expect(warning.shouldWarn()).toBeFalsy();
    warning.initListener();
    return expect(warning.listen).not.toHaveBeenCalled();
  });

  return it("warns when the right elements are in place", function() {
    const warning = new PrintWarning;
    spyOn(warning, "listen");
    setFixtures($("<h2>").addClass("js--print-warning"));
    expect(warning.shouldWarn()).toBeTruthy();
    warning.initListener();
    return expect(warning.listen).toHaveBeenCalled();
  });
});
