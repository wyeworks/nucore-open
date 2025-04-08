/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
//= require sanger_sequencing/columns_first_ordering_strategy

describe("SangerSequencing.ColumnsFirstOrderingStrategy", function() {
  beforeEach(function() {
    return this.strategy = new SangerSequencing.ColumnsFirstOrderingStrategy();
  });

  return it("orders with letters increasing first", function() {
    return expect(this.strategy.fillOrder().slice(0, 10)).toEqual(["A01", "B01", "C01", "D01", "E01",
      "F01", "G01", "H01", "A02", "B02"]);
  });
});
