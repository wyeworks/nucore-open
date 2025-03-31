/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS202: Simplify dynamic range loops
 * DS205: Consider reworking code to avoid use of IIFEs
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
//= require sanger_sequencing/well_plate

describe("SangerSequencing.WellPlateBuilder", function() {
  const sampleList = function(count) {
    if (this.lastSampleId === undefined) { this.lastSampleId = 0; }
    return (() => {
      const result = [];
      for (let x = 0, end = count, asc = 0 <= end; asc ? x < end : x > end; asc ? x++ : x--) {
        this.lastSampleId++;
        result.push(new SangerSequencing.Sample({id: this.lastSampleId, customer_sample_id: `Testing ${x}`}));
      }
      return result;
    })();
  };

  describe("addSubmission()", function() {
    beforeEach(function() {
      this.submission = { id: 542, samples: sampleList(2) };
      return this.wellPlate = new SangerSequencing.WellPlateBuilder;
    });

    it("can add a submission", function() {
      this.wellPlate.addSubmission(this.submission);
      return expect(this.wellPlate.submissions).toEqual([this.submission]);
    });

    return it("cannot add a submission twice", function() {
      this.wellPlate.addSubmission(this.submission);
      this.wellPlate.addSubmission(this.submission);
      return expect(this.wellPlate.submissions).toEqual([this.submission]);
    });
  });

  describe("removeSubmission()", function() {
    beforeEach(function() {
      this.wellPlate = new SangerSequencing.WellPlateBuilder;
      this.submission1 = { id: 542, samples: sampleList(2) };
      this.submission2 = { id: 543, samples: sampleList(3) };
      this.wellPlate.addSubmission(this.submission1);
      return this.wellPlate.addSubmission(this.submission2);
    });

    return it("can remove a submission", function() {
      this.wellPlate.removeSubmission(this.submission1);
      return expect(this.wellPlate.submissions).toEqual([this.submission2]);
    });
  });

  describe("samples()", function() {
    beforeEach(function() {
      this.wellPlate = new SangerSequencing.WellPlateBuilder;
      this.submission1 = { id: 542, samples: sampleList(2) };
      this.submission2 = { id: 543, samples: sampleList(3) };
      this.wellPlate.addSubmission(this.submission1);
      return this.wellPlate.addSubmission(this.submission2);
    });

    return it("returns the samples in order", function() {
      return expect(this.wellPlate.samples()).toEqual(this.submission1.samples.concat(this.submission2.samples));
    });
  });

  describe("sampleAtCell()", function() {
    beforeEach(function() {
      this.wellPlate = new SangerSequencing.WellPlateBuilder;
      this.submission1 = { id: 542, samples: sampleList(2) };
      this.submission2 = { id: 543, samples: sampleList(3) };
      this.wellPlate.addSubmission(this.submission1);
      return this.wellPlate.addSubmission(this.submission2);
    });

    it("finds the first sample at B01 (because the A01 is blank", function() {
      return expect(this.wellPlate.sampleAtCell("B01")).toEqual(this.submission1.samples[0]);
    });

    return describe("when it rolls over into a second plate", function() {
      beforeEach(function() {
        this.submission3 = { id: 544, samples: sampleList(92) };
        return this.wellPlate.addSubmission(this.submission3);
      });

      it("finds the first sample at B01", function() {
        return expect(this.wellPlate.sampleAtCell("B01", 0)).toEqual(this.submission1.samples[0]);
      });

      return it("finds the sample in the second plate at B01", function() {
        // 89 because 96 - 5(already added) - 2 (reserved) = 89
        return expect(this.wellPlate.sampleAtCell("B01", 1)).toEqual(this.submission3.samples[89]);
      });
    });
  });

  describe("plateCount()", function() {
    beforeEach(function() {
      return this.wellPlate = new SangerSequencing.WellPlateBuilder;
    });

    it("has one plate when empty", function() {
      return expect(this.wellPlate.plateCount()).toEqual(1);
    });

    it("has one plate when less than 96 cells", function() {
      this.submission = { id: 542, samples: sampleList(40) };
      this.wellPlate.addSubmission(this.submission);
      return expect(this.wellPlate.plateCount()).toEqual(1);
    });

    it("has one plates when it is completely full", function() {
      this.submission = { id: 542, samples: sampleList(94) };
      this.wellPlate.addSubmission(this.submission);
      return expect(this.wellPlate.plateCount()).toEqual(1);
    });

    it("has two plates when it is just over full", function() {
      this.submission = { id: 542, samples: sampleList(95) };
      this.wellPlate.addSubmission(this.submission);
      return expect(this.wellPlate.plateCount()).toEqual(2);
    });

    return it("has three plates when it gets really big", function() {
      this.submission = { id: 542, samples: sampleList(280) };
      this.wellPlate.addSubmission(this.submission);
      return expect(this.wellPlate.plateCount()).toEqual(3);
    });
  });

  return describe("plates", function() {
    beforeEach(function() {
      this.wellPlate = new SangerSequencing.WellPlateBuilder;
      this.submission = { id: 542, samples: sampleList(8) };
      return this.wellPlate.addSubmission(this.submission);
    });

    it("has 96 cells", function() {
      const results = this.wellPlate.plates[0];
      return expect(Object.keys(results).length).toEqual(96);
    });

    return it("renders odd rows first", function() {
      const results = this.wellPlate.plates[0];
      return (() => {
        const result = [];
        for (var expected of [
        ["A01", "reserved" ],
        ["B01", "Testing 0" ],
        ["C01", "Testing 1" ],
        ["D01", "Testing 2" ],
        ["E01", "Testing 3" ],
        ["F01", "Testing 4" ],
        ["G01", "Testing 5" ],
        ["H01", "Testing 6" ],
        ["A02", "reserved" ],
        ["B02", "" ],
        ["C02", "" ],
        ["D02", "" ],
        ["E02", "" ],
        ["F02", "" ],
        ["G02", "" ],
        ["H02", "" ],
        ["A03", "Testing 7" ],
        ["B03", "" ],
        ["C03", "" ],
        ["D03", "" ],
        ["E03", "" ],
        ["F03", "" ],
        ["G03", "" ],
        ["H03", "" ],
      ]) {
          var well = expected[0];
          var value = expected[1];
          result.push(expect(results[well].customerSampleId()).toEqual(value));
        }
        return result;
      })();
    });
  });
});
