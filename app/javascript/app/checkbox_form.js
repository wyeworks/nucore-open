$(document).ready(function() {
  let submitButton = $(".js--requireValueForSubmit");
  let checkboxes = submitButton.parents("form").find(":checkbox").not('[name="bulk_note_checkbox"]');
  let confirmationMessageEle = document.querySelector(".js--confirmationMessage");
  let reconcileAll = document.querySelector("#js--reconcileAll");

  function toggleCheckBoxes(selectAllSubmitted) {
    $(".js--select_all").each(function() {
      if (selectAllSubmitted) {
        this.innerHTML = $(this).data("select-none");

        if (reconcileAll) {
          reconcileAll.value = true;
        }
      } else {
        this.innerHTML = $(this).data("select-all");

        if (reconcileAll) {
          reconcileAll.value = false;
        }
      }
    });

    $(".toggle:checkbox").each(function() {
      if (!this.disabled) {
        this.checked = selectAllSubmitted;
      }
    });
  }

  function promptUserConfirmation() {
    if (confirmationMessageEle) {
      return confirm(confirmationMessageEle.dataset.confirmMessage);
    } else {
      return true;
    }
  }

  document.querySelectorAll(".js--select_all").forEach((selectAllLink) => {
    selectAllLink.addEventListener("click", function(event) {
      event.preventDefault();

      let selectAllTextPresent = this.innerHTML == this.dataset.selectAll;

      if (selectAllTextPresent) {
        if (promptUserConfirmation()) {
          toggleCheckBoxes(selectAllTextPresent);
        }
      } else {
        toggleCheckBoxes(selectAllTextPresent);
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
