/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
window.vue_sanger_sequencing_well_plate = {
  props: ["builder", "plate-index"],
  template: "#vue-sanger-sequencing-well-plate",

  data() {
    return {plateGrid: SangerSequencing.WellPlateBuilder.grid()};
  },

  beforeCompile() {
    return this.colorBuilder = new SangerSequencing.WellPlateColors(this.builder);
  },

  methods: {
    sampleAtCell(cellName, plateIndex) {
      return this.builder.sampleAtCell(cellName, plateIndex);
    },

    styleForCell(cell, plateIndex) {
      return this.colorBuilder.styleForSubmissionId(this.sampleAtCell(cell.name, plateIndex).submissionId());
    }
  }

};
