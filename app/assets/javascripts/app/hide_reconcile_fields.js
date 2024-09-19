document.addEventListener("DOMContentLoaded", function () {
  const orderStatusSelect = document.querySelector(".js--orderStatusSelect");

  if (!orderStatusSelect) {
    return;
  }

  orderStatusSelect.addEventListener("change", function (event) {
    const selectedValue = event.target.value;

    document
      .querySelectorAll(".js--reconcileField")
      .forEach((reconcileTableField) => {
        if (selectedValue === "reconciled") {
          reconcileTableField.classList.remove("hidden");
        } else {
          reconcileTableField.classList.add("hidden");
        }
      });

    const reconcileOrdersActionRow = document.querySelector(".js--reconcileOrdersContainer");

    if (!reconcileOrdersActionRow) {
      return;
    }

    if (selectedValue === "reconciled") {
      reconcileOrdersActionRow.classList.remove("hidden");
    } else {
      reconcileOrdersActionRow.classList.add("hidden");
    }
  });
});
