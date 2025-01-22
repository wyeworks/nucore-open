/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
SangerSequencing.WellPlateDisplayer = class WellPlateDisplayer {
  constructor(submissions, wellPlates) {
    this.submissions = submissions;
    this.wellPlates = wellPlates;
    this.allSubmissions = this.submissions;
    this.sampleCache = {};
  }

  plateCount() {
    return this.wellPlates.length;
  }

  sampleAtCell(position, plateIndex) {
    const attrs = this.wellPlates[plateIndex][position];

    switch (attrs) {
      case "reserved": return new SangerSequencing.Sample.Reserved;
      case "": return new SangerSequencing.Sample.Blank;
      default: return new SangerSequencing.Sample(attrs);
    }
  }
};
