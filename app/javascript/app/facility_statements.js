document.addEventListener("DOMContentLoaded", function() {
  const createBtn = document.getElementById('create_statement_btn');
  const modal = document.getElementsByClassName('js--statementModal')[0];
  const saveBtn = document.getElementsByClassName('js--saveStatementButton')[0];
  const parentInput = document.getElementById("parent_invoice_number");
  const hiddenInput = document.getElementById("parent_invoice_number_hidden");

  if (createBtn && modal && saveBtn && parentInput && hiddenInput) {
    createBtn.addEventListener('click', function(e) {
      e.preventDefault();

      $(modal).modal('show');
    });

    saveBtn.addEventListener('click', function() {
      hiddenInput.value = parentInput.value.trim();

      $(modal).modal('hide');

      // This is used by the parent statement form, so `journal` doesn't seem right.
      // However, the form is using that name.
      document.getElementById('journals_create_form').submit();
    });

    $(modal).on('hidden.bs.modal', function() {
      parentInput.value = '';
    });
  }

});
