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

  function createEstimateDetailRow(productId, productName, quantity, index) {
    const row = document.createElement("tr");
    row.className = "estimate_detail";
    row.dataset.index = index;

    const productNameCell = document.createElement("td");
    productNameCell.textContent = productName;
    row.appendChild(productNameCell);

    const quantityCell = document.createElement("td");

    const quantityField = document.createElement("input");
    quantityField.type = "number";
    quantityField.min = "1";
    quantityField.value = quantity;
    quantityField.name = `estimate[estimate_details_attributes][${index}][quantity]`;

    quantityCell.appendChild(quantityField);
    row.appendChild(quantityCell);

    const dummyCell = document.createElement("td");

    const productIdField = document.createElement("input");
    productIdField.type = "hidden";
    productIdField.name = `estimate[estimate_details_attributes][${index}][product_id]`;
    productIdField.value = productId;
    dummyCell.appendChild(productIdField);

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

      const productId = productSelect.value;
      const quantity = quantityInput.value;
      const productName =
        productSelect.options[productSelect.selectedIndex].text;

      if (!productId || !productId.length || quantity < 1) {
        return;
      }

      const row = createEstimateDetailRow(
        productId,
        productName,
        quantity,
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
