/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
window.vue_sanger_sequencing_well_plate_editor_app = {
  props: ["submissions"],

  data() {
    return {
      builder: new SangerSequencing.WellPlateBuilder,
      columnOrder: null,
      reservedCells: [],
    };
  },

  beforeCompile() {
    this.colorBuilder = new SangerSequencing.WellPlateColors(this.builder);
  },

  compiled() {
    this.initReservedCellsInput();
  },

  ready() {
    return new AjaxModal(".js--modal", ".js--submissionModal");
  },

  methods: {
    changeOrder() {
      this.builder.changeOrderStrategy(this.columnOrder);
    },

    updateReservedCells(values) {
      this.builder.setReservedCells(values || []);
    },

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
    },
    initReservedCellsInput() {
      let self = this;

      setTimeout(function() {
        let comp = $(self.$els.reservedCells);
        self.updateReservedCells(comp.val());

        comp.chosen().on("change", () => self.updateReservedCells(comp.val()));
      }, 0);
    }
  }

};
