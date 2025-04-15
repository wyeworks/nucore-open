/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
//= require sanger_sequencing/util

describe("SangerSequencing.Util", function() {
  beforeEach(function() {
    return this.util = SangerSequencing.Util;
  });

  return describe("flattenArray", function() {
    it("flattens a 2d array", function() {
      const array = [[1, 2], [3, 4], [5, 6]];
      return expect(this.util.flattenArray(array)).toEqual(
        [1, 2, 3, 4, 5, 6]);
    });

    it("leaves a 1d array alone", function() {
      const array = [1, 2, 3, 4, 5, 6];
      return expect(this.util.flattenArray(array)).toEqual(
        [1, 2, 3, 4, 5, 6]);
    });

    it("handles a mix of single elements and multi elements", function() {
      const array = [1, [2, 3], [4, 5, 6]];
      return expect(this.util.flattenArray(array)).toEqual(
        [1, 2, 3, 4, 5, 6]);
    });

    it("handles an empty array", function() {
      const array = [];
      return expect(this.util.flattenArray(array)).toEqual([]);
    });

    return it("only flattens a single level", function() {
      const array = [1, [2, [3, 4]], [[5, 6]]];
      return expect(this.util.flattenArray(array)).toEqual(
        [1, 2, [3, 4], [5, 6]]);
    });
  });
});
