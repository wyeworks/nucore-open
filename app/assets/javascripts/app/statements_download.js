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
    
    const selectedIds = getSelectedStatementIds();
    
    if (selectedIds.length === 0) {
      alert("Please select at least one statement to download.");
      return;
    }

    downloadButton.disabled = true;
    const formData = createFormData(selectedIds);
    
    fetchStatements(formData)
      .then(data => {
        if (data.pdfs && data.pdfs.length > 0) {
          downloadPdfs(data.pdfs);
        }
        downloadButton.disabled = false;
      })
      .catch(handleError);
  }

  function getSelectedStatementIds() {
    return Array.from(document.querySelectorAll('.js--statement-checkbox:checked'))
      .map(checkbox => checkbox.value);
  }

  function createFormData(selectedIds) {
    const formData = new FormData();
    selectedIds.forEach(id => formData.append('statement_ids[]', id));
    return formData;
  }

  function fetchStatements(formData) {
    return fetch(form.action + '.json', {
      method: 'POST',
      body: formData,
      headers: {
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
        'Accept': 'application/json'
      }
    })
    .then(response => {
      if (!response.ok) throw new Error('Network response was not ok');
      return response.json();
    });
  }

  function downloadPdfs(pdfs) {
    pdfs.forEach((pdf, index) => {
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
