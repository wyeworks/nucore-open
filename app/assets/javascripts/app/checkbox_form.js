$(document).ready(function() {
  var submitButton = $('.js--requireValueForSubmit');
  var checkboxes = submitButton.parents('form').find(':checkbox');

  $('.js--select_all').click(function(e) {
    var check = this.innerHTML == $(this).data("select-all");
    $('.js--select_all').each(function() {
      this.innerHTML = check ? $(this).data("select-none") : $(this).data("select-all");
    });
    $('.toggle:checkbox').each(function() {
      if (!this.disabled) {
        this.checked = check;
      }
    });
    checkboxes.first().trigger('change');
    return false;
  });

  // Disable the submit button if no values are checked
  checkboxes.on('change', function() {
    var checkedCount = checkboxes.filter(":checked");
    submitButton.prop('disabled', checkedCount.length == 0);
  });
  checkboxes.first().trigger('change');
});
