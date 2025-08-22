document.addEventListener("DOMContentLoaded", function() {
  const createBtn = document.getElementById('create_statement_btn');
  const modal = document.getElementById('statement-modal');
  const proceedBtn = document.getElementById("proceed-statement");
  const parentInput = document.getElementById("parent_invoice_number");
  const hiddenInput = document.getElementById("parent_invoice_number_hidden");

  if (!createBtn || !modal || !proceedBtn || !parentInput || !hiddenInput) {
    return;
  }

  createBtn.addEventListener('click', function(e) {
    e.preventDefault();

    const selectedCheckboxes = document.querySelectorAll('table input[type="checkbox"]:checked');
    if (selectedCheckboxes.length === 0) {
      alert('Please select at least one order detail.');
      return;
    }

    $(modal).modal('show');
  });

  proceedBtn.addEventListener('click', function() {
    hiddenInput.value = parentInput.value.trim();

    $(modal).modal('hide');

    // This is used by the parent statement form, so `journal` doesn't seem right.
    // However, the form is using that name.
    document.getElementById('journals_create_form').submit();
  });

  $(modal).on('hidden.bs.modal', function() {
    parentInput.value = '';
  });
});
