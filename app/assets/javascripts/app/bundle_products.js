/**
 * Show/hide helpful hint text on the bundle new page based on which kind of product
 * is selected. The hint text is meant to give the user helpful information about
 * the product type (e.g. Item, Timed Service, etc).
 * 
 * To add a hint, add an element with the .hint and .js--<camel cased product type> 
 * classes to the page. E.g. the "Timed Services" hint is put in an element with the
 * .js--timedServices, and .hint classes.
 */
(function() {
  window.addEventListener("DOMContentLoaded", function() {
    const productSelect = document.querySelector(".js--bundleProducts__productSelect");

    if (productSelect) {
      const hints = document.querySelectorAll(".hint");

      hideElements(hints);

      productSelect.addEventListener("change", function(evt) {
        hideElements(hints);

        let selectedType = $(evt.target).find(":selected").closest("optgroup").attr("label");

        if (selectedType) {
          let className = ".js--" + capitalizedToCamelCase(selectedType);
          document.querySelector(className).hidden = false;
        }

      });
    }

    function capitalizedToCamelCase(str) {
      return (str[0].toLowerCase() + str.slice(1)).replaceAll(" ", "");
    }

    function hideElements(elements) {
      elements.forEach(function(element) {
        element.hidden = true;
      });
    }
  });
})();
