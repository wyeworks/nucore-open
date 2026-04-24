/*
 * Facility User Permission form
 * When any non-read-access permission is checked, auto-check Read Access.
 * Read Access is only unchecked when the admin does it manually.
 */
$(document).ready(function() {
  const readAccessCheckbox = $(".js--readAccessCheckbox");
  const otherCheckboxes = $(".js--otherPermissionCheckbox");

  if (!readAccessCheckbox.length) return;

  otherCheckboxes.on("change", function() {
    if ($(this).is(":checked")) {
      readAccessCheckbox.prop("checked", true);
    }
  });
});
