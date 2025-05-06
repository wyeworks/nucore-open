$(function () {
  const addProductButton = document.getElementById("add_product_to_estimate");

  if (!addProductButton) {
    return;
  }

  if (addProductButton) {
    const productSelect = document.getElementById("product_id");

    if (!productSelect) {
      return;
    }

    const productUrl = productSelect.dataset["productUrl"];

    if (!productUrl) {
      return;
    }

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
  }

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

      if (row.data("estimate_detail_id")) {
        destroyField.val("1");
        row.hide();
      } else {
        row.remove();
      }

      toggleEstimateProductsTable();
    }
  );
});
