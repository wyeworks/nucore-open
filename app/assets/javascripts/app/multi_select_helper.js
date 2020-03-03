const MultiSelectHelper = {
  selectAll: function(select) {
    Array.from(select.options).forEach(function(option) { option.selected = true });
  },

  selectNone: function(select) {
    Array.from(select.options).forEach(function(option) { option.selected = false });
  },

  removeUnselected: function(select) {
    Array.from(select.options).forEach(function(option) {
      if (!option.selected) {
        option.remove();
      }
    });
  }
}
