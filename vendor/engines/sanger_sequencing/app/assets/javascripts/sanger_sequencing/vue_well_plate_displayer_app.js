/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
window.vue_sanger_sequencing_well_plate_displayer_app = {
  props: ["submissions", "well-plates"],

  data() {
    return {builder: new SangerSequencing.WellPlateDisplayer(this.submissions, this.wellPlates)};
  },

  beforeCompile() {
    return this.colorBuilder = new SangerSequencing.WellPlateColors(this.builder);
  },

  ready() {
    return new AjaxModal(".js--modal", ".js--submissionModal");
  },

  methods: {
    styleForSubmissionId(submissionId) {
      return this.colorBuilder.styleForSubmissionId(submissionId);
    },

    isInPlate(submissionId) {
      return true;
    },

    isNotInPlate(submissionId) {
      return !this.isInPlate(submissionId);
    }
  }

};
