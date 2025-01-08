#= require sanger_sequencing/util
#= require sanger_sequencing/columns_first_ordering_strategy

exports = exports ? @

class exports.SangerSequencing.SequentialOrderingStrategy
  fillOrder: ->
    SangerSequencing.Util.flattenArray(@_cellsByColumn())

  _cellsByColumn: ->
    new SangerSequencing.ColumnsFirstOrderingStrategy().cellsByColumn()
