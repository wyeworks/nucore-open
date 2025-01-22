/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS202: Simplify dynamic range loops
 * DS207: Consider shorter variations of null checks
 * DS208: Avoid top-level this
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
//= require sanger_sequencing/odd_first_ordering_strategy
//= require sanger_sequencing/sequential_ordering_strategy

var exports = exports != null ? exports : this;

const ORDER_STRATEGIES = {
  sequential: SangerSequencing.SequentialOrderingStrategy,
  odd_first: SangerSequencing.OddFirstOrderingStrategy,
};

exports.SangerSequencing.WellPlateBuilder = class WellPlateBuilder {

  constructor() {
    this.submissions = [];
    // This array maintains all of the submissions that have ever been added
    // in order to keep consistent colors when removing and adding samples.
    this.allSubmissions = [];
    this._reservedCells = ["A01", "A02"];
    this._orderingStrategy = new SangerSequencing.OddFirstOrderingStrategy;
    this._render();
  }

  changeOrderStrategy(order) {
    const strategyClass = ORDER_STRATEGIES[order];

    if (!strategyClass) { return; }

    this._orderingStrategy = new strategyClass;
    this._render();
  }

  addSubmission(submission) {
    if (!this.isInPlate(submission)) { this.submissions.push(submission); }
    if (!this.hasBeenAddedBefore(submission)) { this.allSubmissions.push(submission); }
    return this._render();
  }

  removeSubmission(submission) {
    const index = this.submissions.indexOf(submission);
    if (index > -1) { this.submissions.splice(index, 1); }
    return this._render();
  }

  setReservedCells(cells) {
    if (cells != null) { this._reservedCells = cells; }
    return this._render();
  }

  isInPlate(submission) {
    return this.submissions.indexOf(submission) >= 0;
  }

  hasBeenAddedBefore(submission) {
    return this.allSubmissions.indexOf(submission) >= 0;
  }

  sampleAtCell(cell, plateIndex) {
    if (plateIndex == null) { plateIndex = 0; }
    return this.plates[plateIndex][cell];
  }

  samples() {
    return SangerSequencing.Util.flattenArray(this.submissions.map(submission => submission.samples.map(function(s) {
      if (s instanceof SangerSequencing.Sample) { return s; } else { return new SangerSequencing.Sample(s); }})));
  }

  plateCount() {
    return this._plateCount;
  }

  static grid() {
    return Array.from("ABCDEFGH").map((ch) => ({
      name: ch,
      cells: ["01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12"].map((num) => ({
        column: num,
        name: `${ch}${num}`
      }))
    }));
  }

  // Private

  _render() {
    const wellsInPlate = this._fillOrder().length - this._reservedCells.length;
    this._plateCount = Math.max(1, Math.ceil(this.samples().length / wellsInPlate));

    const samples = this.samples();
    const allPlates = [];

    for (let plate = 0, end = this.plateCount(), asc = 0 <= end; asc ? plate <= end : plate >= end; asc ? plate++ : plate--) {
      allPlates.push(this._renderPlate(samples));
    }

    return this.plates = allPlates;
  }

  _renderPlate(samples) {
    const plate = {};

    for (var cellName of Array.from(this._fillOrder())) {
      var sample;
      plate[cellName] = this._reservedCells.indexOf(cellName) < 0 ?
        (sample = samples.shift()) ?
          sample
        :
          new SangerSequencing.Sample.Blank
      :
        // Reserved will actually take up a cell, while ReservedButUnused is
        // for when we have not actually reached that cell in the fill order,
        // so it will instead be treated as blank.
        samples.length > 0 ?
          new SangerSequencing.Sample.Reserved
        :
          new SangerSequencing.Sample.ReservedButUnused;

      sample;
    }

    return plate;
  }

  _fillOrder() {
    return this._orderingStrategy.fillOrder();
  }
};
