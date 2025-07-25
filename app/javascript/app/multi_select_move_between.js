document.addEventListener("DOMContentLoaded", function() {
  function moveSelected(fromSelect, toSelect) {
    MultiSelectHelper.selectNone(toSelect);
    const selected = Array.from(fromSelect.options).filter(function(option) { return option.selected });
    selected.forEach(function(option) {
      toSelect.options.add(option);
    })
  }

  Array.from(document.getElementsByClassName("js--moveBetweenSelects")).forEach(function(parent) {
    const includedSelect = parent.querySelector(".js--included");
    const excludedSelect = parent.querySelector(".js--excluded");

    // The included select box should start with ALL the possible values included
    // and have the actual included values selected. This way, the page would still
    // work without Javascript.
    MultiSelectHelper.removeUnselected(includedSelect);
    MultiSelectHelper.selectNone(includedSelect);
    MultiSelectHelper.selectNone(excludedSelect);

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
      MultiSelectHelper.selectAll(includedSelect);
      excludedSelect.disabled = true;
      evt.target.submit();
    });
  });
});
