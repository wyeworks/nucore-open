/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS207: Consider shorter variations of null checks
 * DS208: Avoid top-level this
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
//= require sanger_sequencing/util
//= require sanger_sequencing/columns_first_ordering_strategy

var exports = exports != null ? exports : this;

exports.SangerSequencing.OddFirstOrderingStrategy = class OddFirstOrderingStrategy {
  fillOrder() {
    let i, column;
    const odds = ((() => {
      const result = [];
      const iterable = this._cellsByColumn();
      for (i = 0; i < iterable.length; i++) {
        column = iterable[i];
        if ((i % 2) === 0) {
          result.push(column);
        }
      }
      return result;
    })());
    const evens = ((() => {
      const result1 = [];
      const iterable1 = this._cellsByColumn();
      for (i = 0; i < iterable1.length; i++) {
        column = iterable1[i];
        if ((i % 2) === 1) {
          result1.push(column);
        }
      }
      return result1;
    })());
    return SangerSequencing.Util.flattenArray(odds.concat(evens));
  }

  _cellsByColumn() {
    return new SangerSequencing.ColumnsFirstOrderingStrategy().cellsByColumn();
  }
};
