/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
//= require sanger_sequencing/rows_first_ordering_strategy

describe("SangerSequencing.RowsFirstOrderingStrategy", function() {
  beforeEach(function() {
    return this.strategy = new SangerSequencing.RowsFirstOrderingStrategy();
  });

  return it("orders with numbers increasing first", function() {
    return expect(this.strategy.fillOrder().slice(0, 14)).toEqual(["A01", "A02", "A03", "A04", "A05",
      "A06", "A07", "A08", "A09", "A10", "A11", "A12", "B01", "B02"]);
  });
});
