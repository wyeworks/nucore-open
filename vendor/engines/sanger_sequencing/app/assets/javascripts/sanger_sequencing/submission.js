/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */

const SubmissionForm = {
  handleCopyPrimer(event) {
    const row = $(event.target).parents("tr");

    if (row.length == 0) { return; }
    const primerName = row.find(".js--primerName").val()

    row.nextAll(":visible").find(".js--primerName").val(primerName);
  },
  setupCopyPrimerCallback(element) {
    $(element).on("click", this.handleCopyPrimer);
  }
};

(function() {
  $(document).ready(function() {
    SubmissionForm.setupCopyPrimerCallback($(".js--copyPrimerNameDown"));
  });
}());

$(() => $(document).on("fields_added.nested_form_fields", function(event) {
  const sangerSequencingForm = $("form.edit_sanger_sequencing_submission");
  if (!(sangerSequencingForm.length > 0)) { return; }
  const row = $(event.target);
  const customerSampleIdField = row.find(".js--customerSampleId");
  const prevSamplePrimerName = row.prevAll(":visible:first").find(".js--primerName").val();

  SubmissionForm.setupCopyPrimerCallback(row);

  customerSampleIdField.prop("disabled", true).val("Loading...");
  $.post(sangerSequencingForm.data("create-sample-url")).done(function(sample) {
    customerSampleIdField.prop("disabled", false).val(sample.customer_sample_id);
    row.find(".js--sampleId").val(sample.id).text(sample.id);
    if (prevSamplePrimerName) {
      row.find(".js--primerName").val(prevSamplePrimerName);
    }
  });
}));
