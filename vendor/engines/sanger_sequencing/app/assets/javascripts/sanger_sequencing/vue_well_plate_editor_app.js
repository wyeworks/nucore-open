/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
window.vue_sanger_sequencing_well_plate_editor_app = {
  props: ["submissions", "builder_config"],

  data() {
    return {builder: new SangerSequencing.WellPlateBuilder};
  },

  beforeCompile() {
    this.colorBuilder = new SangerSequencing.WellPlateColors(this.builder);
    return this.builder.setReservedCells(this.builder_config.reserved_cells);
  },

  ready() {
    return new AjaxModal(".js--modal", ".js--submissionModal");
  },

  methods: {
    addSubmission(submissionId) {
      return this.builder.addSubmission(this.findSubmission(submissionId));
    },

    removeSubmission(submissionId) {
      return this.builder.removeSubmission(this.findSubmission(submissionId));
    },

    submissionIds() {
      return this.builder.submissions.map(submission => submission.id);
    },

    findSubmission(submissionId) {
      return this.submissions.filter(submission => {
        return submission.id === submissionId;
      })[0];
    },

    styleForSubmissionId(submissionId) {
      return this.colorBuilder.styleForSubmissionId(submissionId);
    },

    isInPlate(submissionId) {
      return this.builder.isInPlate(this.findSubmission(submissionId));
    },

    isNotInPlate(submissionId) {
      return !this.isInPlate(submissionId);
    }
  }

};
