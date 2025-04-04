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
        const reconcile = selectedValue == RECONCILED;
        if (reconcile) {
          reconcileTableField.classList.remove("hidden");
        } else {
          reconcileTableField.classList.add("hidden");
        }
        reconcileTableField.querySelectorAll("input").forEach((inputEl) => {
          inputEl.disabled = !reconcile
        });
      });

    document
      .querySelectorAll(".js--unrecoverableField")
      .forEach((element) => {
        const unrecoverable = selectedValue == UNRECOVERABLE;
        if (unrecoverable) {
          element.classList.remove("hidden");
        } else {
          element.classList.add("hidden");
        }
        element.querySelectorAll("input").forEach((inputEl) => {
          inputEl.disabled = !unrecoverable
        });
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
