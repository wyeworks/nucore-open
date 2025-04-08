/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
$(function() {
  // The modal is present on the page after ending of a reservation. Auto-log
  // the user out of their session after 60 seconds.
  const $logoutModal = $("#logout_modal");
  if ($logoutModal.length > 0) {
    $logoutModal.modal("show");
    const logoutLink = $logoutModal.find(".logout").attr("href");
    return window.setTimeout((() => window.location.href = logoutLink), 60000);
  }
});
