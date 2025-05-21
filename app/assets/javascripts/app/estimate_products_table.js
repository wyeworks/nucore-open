$(function () {
  const facilitySelect = $("#facility_id");
  const productSelect = document.getElementById("product_id");
  const addProductButton = document.getElementById("add_product_to_estimate");

  if (!facilitySelect || !productSelect || !addProductButton) {
    return;
  }

  const productUrl = productSelect.dataset["productUrl"];
  const originalFacility = facilitySelect.data("originalFacility");

  if (!productUrl) {
    return;
  }

  facilitySelect.on("change", (event) => {
    const selectedOption = $(event.target).find(":selected");
    const productsPath = selectedOption.data("products-path");

    if (!productsPath) {
      return;
    }

    $.ajax({
      url: productsPath,
      type: "GET",
      dataType: "json",
      data: { is_estimate: true, original_facility: originalFacility },
      success: function(data) {
        $(productSelect).empty();

        data.forEach(function(product) {
          const option = new Option(product.name, product.id);
          $(productSelect).append(option);
        });

        $(productSelect).trigger('chosen:updated');
      }
    });
  });

  addProductButton.addEventListener("click", function () {
    const productId = productSelect.value;

    if (!productId || !productId.length) {
      return;
    }

    $.ajax({
      url: `${productUrl}?product_id=${productId}`,
      type: "GET",
      dataType: "script",
    });
  });

  const toggleEstimateProductsTable = () => {
    if ($("#new_estimate_estimate_details tr:visible").length === 0) {
      $("#new_estimate_products_table").hide();
    } else {
      $("#new_estimate_products_table").show();
    }
  }

  const initializeTimedFields = () => {
    const estimateDurationMinsInputs = $(".js--estimate-duration-mins");

    estimateDurationMinsInputs.timeinput();
  }

  toggleEstimateProductsTable();
  initializeTimedFields();

  $("#new_estimate_products_table").on(
    "click",
    ".remove-estimate-detail",
    function (e) {
      e.preventDefault();
      var row = $(this).closest("tr");
      var destroyField = row.find(".destroy-field");

      if (destroyField.length) {
        destroyField.val(true);
        row.hide();
      } else {
        row.remove();
      }

      toggleEstimateProductsTable();
    }
  );
});
