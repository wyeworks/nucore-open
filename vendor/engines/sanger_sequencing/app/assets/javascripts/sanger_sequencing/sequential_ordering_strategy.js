//= require sanger_sequencing/util
//= require sanger_sequencing/columns_first_ordering_strategy

var exports = exports != null ? exports : this;

exports.SangerSequencing.SequentialOrderingStrategy = class SequentialOrderingStrategy {
  fillOrder() {
    return SangerSequencing.Util.flattenArray(this._cellsByColumn());
  }

  _cellsByColumn() {
    return new SangerSequencing.ColumnsFirstOrderingStrategy().cellsByColumn();
  }
};
