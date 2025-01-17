/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * DS208: Avoid top-level this
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
//= require sanger_sequencing/util
var exports = exports != null ? exports : this;

exports.SangerSequencing.ColumnsFirstOrderingStrategy = class ColumnsFirstOrderingStrategy {
  fillOrder() {
    return SangerSequencing.Util.flattenArray(this.cellsByColumn());
  }

  cellsByColumn() {
    return ["01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12"].map((num) =>
      Array.from("ABCDEFGH").map((ch) =>
        `${ch}${num}`));
  }
};
