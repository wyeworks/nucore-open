/*
 * Price Group Form
 * Handles toggle visibility of subsidy section based on is_internal checkbox
 */
$(document).ready(function() {
  const isInternalCheckbox = $(".js--isInternal");
  const subsidySection = $(".js--subsidySection");

  if (isInternalCheckbox.length && subsidySection.length) {
    isInternalCheckbox.on("change", function() {
      if ($(this).is(":checked")) {
        subsidySection.hide();
        subsidySection.find("select").val("");
      } else {
        subsidySection.show();
      }
    });
  }
});
