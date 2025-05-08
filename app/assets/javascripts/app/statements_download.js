document.addEventListener('DOMContentLoaded', function() {
  var checkboxes = document.querySelectorAll('.js--statement-checkbox');
  var selectAllCheckbox = document.querySelector('.js--select-all-statements');
  var downloadButton = document.querySelector('.js--download-selected-statements');
  var form = document.getElementById('statements-form');

  if (!checkboxes || checkboxes.length === 0) {
    return;
  }

  initializeCheckboxes();
  updateButtonState();

  function updateButtonState() {
    var checkedCount = document.querySelectorAll('.js--statement-checkbox:checked').length;
    if (downloadButton) {
      downloadButton.disabled = checkedCount === 0;
    }
  }


  function initializeCheckboxes() {
    if (checkboxes && checkboxes.length > 0) {
      checkboxes.forEach(function(checkbox) {
        checkbox.addEventListener('change', updateButtonState);
      });
    }

    if (selectAllCheckbox) {
      selectAllCheckbox.addEventListener('change', function() {
        checkboxes.forEach(function(checkbox) {
          checkbox.checked = selectAllCheckbox.checked;
        });
        updateButtonState();
      });
    }

    if (form) {
      form.addEventListener('submit', handleFormSubmit);
    }
  }

  function handleFormSubmit(event) {
    event.preventDefault();

    const selectedCheckboxes = getSelectedCheckboxes();

    if (selectedCheckboxes.length === 0) {
      alert("Please select at least one statement to download.");
      return;
    }

    downloadButton.disabled = true;

    try {
      const pdfUrls = getPdfUrls(selectedCheckboxes);
      downloadStatementPdfs(pdfUrls);

      setTimeout(() => {
        downloadButton.disabled = false;
      }, selectedCheckboxes.length * 1000);
    } catch (error) {
      handleError(error);
    }
  }

  function getSelectedCheckboxes() {
    return Array.from(document.querySelectorAll('.js--statement-checkbox:checked'));
  }

  function getPdfUrls(selectedCheckboxes) {
    return selectedCheckboxes.map(checkbox => {
      const statementRow = checkbox.closest('tr.statement');
      const pdfLink = statementRow.querySelector('a[href*=".pdf"]') || 
                      statementRow.querySelector('a[href*="statements"]');

      if (!pdfLink) {
        throw new Error('Could not find PDF link for one or more selected statements');
      }

      return {
        url: pdfLink.href,
        invoiceNumber: checkbox.dataset.invoiceNumber || 'statement'
      };
    });
  }

  function downloadStatementPdfs(pdfUrls) {
    pdfUrls.forEach((pdf, index) => {
      setTimeout(() => {
        const a = document.createElement('a');
        a.style.display = 'none';
        a.href = pdf.url;
        a.download = true;
        document.body.appendChild(a);
        a.click();
      }, index * 1000);
    });
  }

  function handleError(error) {
    console.error('Error:', error);
    alert('There was an error downloading the statements. Please try again.');
    downloadButton.disabled = false;
  }
});
