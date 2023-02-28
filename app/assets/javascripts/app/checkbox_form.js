$(document).ready(function() {
  let submitButton = $(".js--requireValueForSubmit");
  let checkboxes = submitButton.parents("form").find(":checkbox");
  let confirmationSpan = document.querySelector(".js--confirmationSpan");

  function toggleCheckBoxes(selectAllSubmitted) {
    $(".js--select_all").each(function() {
      this.innerHTML = selectAllSubmitted ? $(this).data("select-none") : $(this).data("select-all");
    });

    $(".toggle:checkbox").each(function() {
      if (!this.disabled) {
        this.checked = selectAllSubmitted;
      }
    });
  }

  function promptUserConfirmation() {
    if (confirmationSpan) {
      return confirm(confirmationSpan.dataset.confirmMessage);
    } else {
      return true;
    }
  }

  document.querySelectorAll(".js--select_all").forEach((selectAllLink) => {
    selectAllLink.addEventListener("click", function(event) {
      event.preventDefault();

      let selectAllSubmitted = this.innerHTML == this.dataset.selectAll;

      if (selectAllSubmitted && promptUserConfirmation()) {
        toggleCheckBoxes(selectAllSubmitted);
      } else {
        toggleCheckBoxes(selectAllSubmitted);
      }
      checkboxes.first().trigger("change");
    });
  });

  // Disable the submit button if no values are checked
  checkboxes.on("change", function() {
    let checkedCount = checkboxes.filter(":checked");
    submitButton.prop("disabled", checkedCount.length == 0);
  });
  checkboxes.first().trigger("change");
});
