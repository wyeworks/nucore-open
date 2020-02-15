document.addEventListener("DOMContentLoaded", function() {
  function moveSelected(fromSelect, toSelect) {
    clearSelected(toSelect);
    const selected = Array.from(fromSelect.options).filter(function(option) { return option.selected });
    selected.forEach(function(option) {
      toSelect.options.add(option);
    })
  }

  function clearSelected(select) {
    Array.from(select.options).forEach(function(option) { option.selected = false });
  }

  function selectAll(select) {
    Array.from(select.options).forEach(function(option) { option.selected = true });
  }

  function removeUnselected(included) {
    Array.from(included.options).forEach(function(option) {
      if (!option.selected) {
        option.remove();
      }
    });
  }

  Array.from(document.getElementsByClassName("js--moveBetweenSelects")).forEach(function(parent) {
    const includedSelect = parent.querySelector(".js--included");
    const excludedSelect = parent.querySelector(".js--excluded");

    // The included select box should start with ALL the possible values included
    // and have the actual included values selected. This way, the page would still
    // work without Javascript.
    removeUnselected(includedSelect);
    clearSelected(includedSelect);
    clearSelected(excludedSelect);

    parent.querySelector(".js--include").addEventListener("click", function(evt) {
      evt.preventDefault();
      moveSelected(excludedSelect, includedSelect);
    });

    parent.querySelector(".js--exclude").addEventListener("click", function(evt) {
      evt.preventDefault();
      moveSelected(includedSelect, excludedSelect);
    })

    parent.closest("form").addEventListener("submit", function(evt) {
      evt.preventDefault();
      selectAll(includedSelect);
      excludedSelect.disabled = true;
      evt.target.submit();
    });
  });
});
