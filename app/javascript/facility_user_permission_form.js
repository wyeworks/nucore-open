/*
 * Facility User Permission form
 *
 * Two invariants are enforced visually here (and server-side in the model):
 * - Read Access is required whenever any other permission is active.
 *   Checking another permission auto-checks Read Access and locks it
 *   (visually disabled and unclickable). When all other permissions
 *   are unchecked, Read Access becomes editable again.
 * - Granting Product Creation implies Product Editing. Checking Product
 *   Creation auto-checks Product Editing and locks it. Unchecking Product
 *   Creation releases the lock (Product Editing keeps its current state).
 */
$(document).ready(function() {
  const readAccessCheckbox = $(".js--readAccessCheckbox");
  const otherCheckboxes = $(".js--otherPermissionCheckbox");
  const creationCheckbox = $(".js--productCreationCheckbox");
  const editionCheckbox = $(".js--productEditionCheckbox");

  function lock($checkbox) {
    $checkbox.attr("data-locked", "true").css("opacity", "0.5");
  }

  function unlock($checkbox) {
    $checkbox.removeAttr("data-locked").css("opacity", "");
  }

  function syncReadAccess() {
    if (otherCheckboxes.is(":checked")) {
      readAccessCheckbox.prop("checked", true);
      lock(readAccessCheckbox);
    } else {
      unlock(readAccessCheckbox);
    }
  }

  function syncProductEdition() {
    if (creationCheckbox.is(":checked")) {
      editionCheckbox.prop("checked", true);
      lock(editionCheckbox);
    } else {
      unlock(editionCheckbox);
    }
  }

  function preventClickWhenLocked(event) {
    if ($(this).attr("data-locked") === "true") {
      event.preventDefault();
    }
  }

  readAccessCheckbox.on("click", preventClickWhenLocked);
  editionCheckbox.on("click", preventClickWhenLocked);

  otherCheckboxes.on("change", syncReadAccess);
  creationCheckbox.on("change", syncProductEdition);

  syncReadAccess();
  syncProductEdition();
});
