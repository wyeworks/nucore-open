document.addEventListener("DOMContentLoaded", function() {
  const selectAllLink = document.querySelector(".js--select_all");
  const table = document.querySelector("table.js--transactions-table");
  const submitDiv = document.querySelector(".submit");
  const journalCreationSubmitButton = document.querySelector(".js--journal-creation__submit");
  const journalCreationHelperText = document.querySelector(".js--journal-creation__helper");
  let earliestFulfilledAtDate;

  table.addEventListener("click", setEarliestFulfilledAtDate);
  selectAllLink.addEventListener("click", setEarliestFulfilledAtDate);
  submitDiv.addEventListener("click", handleModals);
  if (journalCreationSubmitButton) {
    journalCreationSubmitButton.addEventListener("click", handleSubmit);
  }

  function setEarliestFulfilledAtDate(event) {
    const fulfilledAtDates = [];
    const checked = document.querySelectorAll("table.js--transactions-table tr td input[type='checkbox']:checked");

    checked.forEach(checkedBox => {
      const row = checkedBox.parentElement.parentElement;
      const date = new Date(row.querySelector(".js--date-field").innerHTML);
      fulfilledAtDates.push(date);
    });

    fulfilledAtDates.sort((a, b) => a.getTime() - b.getTime());
    earliestFulfilledAtDate = fulfilledAtDates[0];
  }

  function handleModals(event) {
    const journalDateInput = document.querySelector("#journal_date");
    const journalDate = new Date(journalDateInput.value);

    const dateDiff = moment(journalDate).diff(earliestFulfilledAtDate, "days");
    const atLeastOneRowChecked = typeof(earliestFulfilledAtDate) === "object" && earliestFulfilledAtDate !== null

    if (atLeastOneRowChecked && dateDiff >= 90) {
      event.preventDefault();
      $("#journal-date-popup").modal("show");
    }
    else if ($("#journal-creation-reminder").length) {
      event.preventDefault();
      $("#journal-creation-reminder").modal("show");
    }
  }

  function handleSubmit(event) {
    event.preventDefault();
    event.target.disabled = true;
    journalCreationHelperText.toggleAttribute("hidden");
    document.getElementById("journals_create_form").submit();
  }
});
