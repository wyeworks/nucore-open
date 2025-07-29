/** 
 * Show and require the "Fulfilled at" field only if the "Order Status" is 
 * "Complete", this is currently done in the _edit_date partial.
 * 
 * TODO: The SetFulfilledOnComplete class does something similar to this,
 *       so it may be a good idea to generalize this function to replace
 *       that class.
**/
function toggleFulfilledAtSection(orderStatusSelectElem) {
  const fulfilledAtSection = document.querySelector(".backdate_fulfilled_at");
  const fulfilledAtElement = document.querySelector(".js--fulfilled_at");
  let selectedIndex = orderStatusSelectElem.selectedIndex;
  let selectedText = orderStatusSelectElem.options[selectedIndex].text; 
  let displayStyle;
  let required;

  if (selectedText === "Complete") {
    displayStyle = "";
    required = true;
  }
  else {
    displayStyle = "none";
    required = false;
    fulfilledAtElement.value = null;
  }

  fulfilledAtSection.style.display = displayStyle;
  fulfilledAtElement.required = required;
}


window.addEventListener("DOMContentLoaded", () => {
  const orderStatusSelect = document.querySelector(".js--order_status");

  if (orderStatusSelect) {
    toggleFulfilledAtSection(orderStatusSelect);
    orderStatusSelect.addEventListener("change", () => toggleFulfilledAtSection(orderStatusSelect));
  }
});
