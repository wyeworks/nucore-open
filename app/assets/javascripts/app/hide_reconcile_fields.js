document.addEventListener("DOMContentLoaded", function () {
  const RECONCILED = "reconciled";
  const UNRECOVERABLE = "unrecoverable";
  const orderStatusSelect = document.querySelector(".js--orderStatusSelect");

  if (!orderStatusSelect) {
    return;
  }

  const showRecinciledNoteStatus = [
    RECONCILED, UNRECOVERABLE
  ];

  orderStatusSelect.addEventListener("change", function (event) {
    const selectedValue = event.target.value;

    document
      .querySelectorAll(".js--reconcileField")
      .forEach((reconcileTableField) => {
        if (selectedValue == RECONCILED) {
          reconcileTableField.classList.remove("hidden");
        } else {
          reconcileTableField.classList.add("hidden");
        }
      });

    document
      .querySelectorAll(".js--unrecoverableField")
      .forEach((element) => {
        if (selectedValue == UNRECOVERABLE) {
          element.classList.remove("hidden");
        } else {
          element.classList.add("hidden");
        }
      })

    const reconcileOrdersActionRow = document.querySelector(".js--reconcileOrdersContainer");

    if (!reconcileOrdersActionRow) {
      return;
    }

    if (selectedValue === RECONCILED) {
      reconcileOrdersActionRow.classList.remove("hidden");
    } else {
      reconcileOrdersActionRow.classList.add("hidden");
    }
  });
});
