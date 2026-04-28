/*
 * Facility User Permission form
 * Read Access is required whenever any other permission is active.
 * Checking another permission auto-checks Read Access and locks it
 * (visually disabled and unclickable). When all other permissions
 * are unchecked, Read Access becomes editable again.
 */
$(document).ready(function() {
  const readAccessCheckbox = $(".js--readAccessCheckbox");
  const otherCheckboxes = $(".js--otherPermissionCheckbox");

  function syncReadAccess() {
    const anyOtherChecked = otherCheckboxes.is(":checked");
    if (anyOtherChecked) {
      readAccessCheckbox.prop("checked", true);
      readAccessCheckbox.attr("data-locked", "true").css("opacity", "0.5");
    } else {
      readAccessCheckbox.removeAttr("data-locked").css("opacity", "");
    }
  }

  readAccessCheckbox.on("click", function(event) {
    if ($(this).attr("data-locked") === "true") {
      event.preventDefault();
    }
  });

  otherCheckboxes.on("change", syncReadAccess);
  syncReadAccess();
});
