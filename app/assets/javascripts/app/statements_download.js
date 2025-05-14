document.addEventListener('DOMContentLoaded', function() {
  const checkboxes = document.querySelectorAll('.js--statement-checkbox');
  const selectAllCheckbox = document.querySelector('.js--select-all-statements');
  const downloadButton = document.querySelector('.js--download-selected-statements');
  const form = document.getElementById('statements-form');

  if (!checkboxes || checkboxes.length === 0) {
    return;
  }

  initializeCheckboxes();
  updateButtonState();

  function updateButtonState() {
    const checkedCount = document.querySelectorAll('.js--statement-checkbox:checked').length;
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

    if (downloadButton) {
      downloadButton.addEventListener('click', handleDownload);
    }
  }

  function handleDownload() {
    const selectedCheckboxes = getSelectedCheckboxes();

    if (selectedCheckboxes.length === 0) {
      return;
    }

    downloadButton.disabled = true;

    try {
      const pdfUrls = getPdfUrls(selectedCheckboxes);
      downloadStatementPdfs(pdfUrls);

      setTimeout(() => {
        downloadButton.disabled = false;
      }, selectedCheckboxes.length * 200);
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
      }, index * 200);
    });
  }

  function handleError(error) {
    console.error('Error:', error);
    downloadButton.disabled = false;
  }
});
