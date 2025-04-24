$(function () {
  let productCounter = 0;
  const addProductButton = document.getElementById("add_product_to_estimate");
  const estimateDetailsContainer = document.getElementById(
    "new_estimate_estimate_details"
  );
  const productsTable = document.getElementById("new_estimate_products_table");

  if (!addProductButton || !estimateDetailsContainer || !productsTable) {
    return;
  }

  const removeButtonText = estimateDetailsContainer.dataset.removeButtonText;

  function toggleTable() {
    const rows = estimateDetailsContainer.querySelectorAll(".estimate_detail");

    if (rows.length > 0) {
      productsTable.classList.remove("hidden");
    } else {
      productsTable.classList.add("hidden");
    }
  }

  function createEstimateDetailRow(productId, productName, quantity, durationMins, durationMinsDisplay, durationDays, index) {
    const row = document.createElement("tr");
    row.className = "estimate_detail";
    row.dataset.index = index;

    const dummyCell = document.createElement("td");

    const productNameCell = document.createElement("td");
    productNameCell.textContent = productName;
    row.appendChild(productNameCell);

    const quantityCell = document.createElement("td");
    const quantityField = document.createElement("input");
    quantityField.type = "number";
    quantityField.min = "1";
    quantityField.value = quantity;
    quantityField.name = `estimate[estimate_details_attributes][${index}][quantity]`;

    if (durationMins || durationDays) {
      quantityCell.textContent = 1;

      quantityField.type = "hidden";
      dummyCell.appendChild(quantityField);
    } else {
      quantityCell.appendChild(quantityField);
    }

    row.appendChild(quantityCell);

    const durationCell = document.createElement("td");

    if (durationDays) {
      durationCell.textContent = durationDays;
    } else if (durationMins) {
      durationCell.textContent = durationMinsDisplay;
    }

    row.appendChild(durationCell);

    const productIdField = document.createElement("input");
    productIdField.type = "hidden";
    productIdField.name = `estimate[estimate_details_attributes][${index}][product_id]`;
    productIdField.value = productId;
    dummyCell.appendChild(productIdField);

    const durationDaysField = document.createElement("input");
    durationDaysField.type = "hidden";
    durationDaysField.name = `estimate[estimate_details_attributes][${index}][duration_days]`;
    durationDaysField.value = durationDays;
    dummyCell.appendChild(durationDaysField);

    const durationMinsField = document.createElement("input");
    durationMinsField.type = "hidden";
    durationMinsField.name = `estimate[estimate_details_attributes][${index}][duration_mins]`;
    durationMinsField.value = durationMins;
    dummyCell.appendChild(durationMinsField);

    const removeButton = document.createElement("button");
    removeButton.type = "button";
    removeButton.className = "btn";
    removeButton.textContent = removeButtonText;
    removeButton.addEventListener("click", function () {
      row.remove();
      toggleTable();
    });
    dummyCell.appendChild(removeButton);

    row.appendChild(dummyCell);

    return row;
  }

  if (addProductButton) {
    addProductButton.addEventListener("click", function () {
      const productSelect = document.getElementById("product_id");
      const quantityInput = document.getElementById("quantity");
      const durationMinsInput = document.getElementsByName("duration_mins")[0];
      const durationMinsDisplayInput = document.getElementById("duration_mins");
      const durationDaysInput = document.getElementById("duration_days");

      const productId = productSelect.value;
      const quantity = quantityInput.value;
      const durationMins = durationMinsInput.disabled ? null : durationMinsInput.value;
      const durationMinsDisplay = durationMinsDisplayInput.value;
      const durationDays = durationDaysInput.disabled ? null : durationDaysInput.value;
      const productName =
        productSelect.options[productSelect.selectedIndex].text;

      if (!productId || !productId.length || quantity < 1) {
        return;
      }

      const row = createEstimateDetailRow(
        productId,
        productName,
        quantity,
        durationMins,
        durationMinsDisplay,
        durationDays,
        productCounter
      );
      estimateDetailsContainer.appendChild(row);

      productCounter++;

      quantityInput.value = 1;

      toggleTable();
    });
  }

  toggleTable();
});

$(function () {
  const estimateProductInput = $(".js--estimate-product");
  const estimateQuantityInput = $(".js--estimate-quantity");
  const estimateDurationDaysContainer = $(
    ".js--estimate-duration-days-container"
  );
  const estimateDurationMinsContainer = $(
    ".js--estimate-duration-mins-container"
  );
  const estimateDurationDaysInput = $(".js--estimate-duration-days");
  const estimateDurationMinsInput = $(".js--estimate-duration-mins");

  if (
    !estimateProductInput.length ||
    !estimateQuantityInput.length ||
    !estimateDurationDaysContainer.length ||
    !estimateDurationMinsContainer.length ||
    !estimateDurationDaysInput.length ||
    !estimateDurationMinsInput.length
  ) {
    return;
  }

  estimateDurationMinsInput.timeinput();
  const estimateDurationMinsInputHidden = estimateDurationMinsInput.data("timeparser").$hidden_field;

  const updateTimedFields = (timeUnit) => {
    const isTimed = timeUnit?.length > 0;

    if (isTimed) {
      const dailyTimed = timeUnit === "days";
      estimateDurationDaysInput.prop("disabled", !dailyTimed);
      estimateDurationMinsInput.prop("disabled", dailyTimed);
      estimateDurationMinsInputHidden.prop("disabled", dailyTimed);

      if (dailyTimed) {
        estimateDurationDaysContainer.removeClass("hidden");
        estimateDurationMinsContainer.addClass("hidden");
      } else {
        estimateDurationMinsContainer.removeClass("hidden");
        estimateDurationDaysContainer.addClass("hidden");
      }
    } else {
      estimateDurationDaysContainer.addClass("hidden");
      estimateDurationMinsContainer.addClass("hidden");
      estimateDurationDaysInput.prop("disabled", true);
      estimateDurationMinsInput.prop("disabled", true);
      estimateDurationMinsInputHidden.prop("disabled", true);
    }

    if (isTimed) {
      estimateQuantityInput.val(1);
    }

    estimateQuantityInput.prop("disabled", isTimed);
  };

  const initializeTimedFields = () => {
    const initialSelectedOpetion = estimateProductInput.find(":selected");
    const initialTimeUnit = initialSelectedOpetion.data("time-unit");
    updateTimedFields(initialTimeUnit);
  };

  initializeTimedFields();

  estimateProductInput.on("change", function (event) {
    const timeUnit = $(event.target).find(":selected").data("time-unit");

    updateTimedFields(timeUnit);
  });
});
