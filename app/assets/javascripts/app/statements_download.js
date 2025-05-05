document.addEventListener('DOMContentLoaded', function() {
  var checkboxes = document.querySelectorAll('.js--statement-checkbox');
  var selectAllCheckbox = document.querySelector('.js--select-all-statements');
  var downloadButton = document.querySelector('.js--download-selected-statements');
  var form = document.getElementById('statements-form');

  if (!checkboxes || checkboxes.length === 0) {
    return;
  }

  function updateButtonState() {
    var checkedCount = document.querySelectorAll('.js--statement-checkbox:checked').length;
    if (downloadButton) {
      downloadButton.disabled = checkedCount === 0;
    }
  }

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
    form.addEventListener('submit', function(event) {
      var selectedIds = Array.from(document.querySelectorAll('.js--statement-checkbox:checked'))
        .map(function(cb) { return cb.value; });

      if (selectedIds.length === 0) {
        event.preventDefault();
        alert("Please select at least one statement to download.");
        return;
      }

      downloadButton.disabled = true;

      if (selectedIds.length === 1) {
        event.preventDefault();

        const formData = new FormData();
        formData.append('statement_ids[]', selectedIds[0]);

        fetch(form.action, {
          method: 'POST',
          body: formData,
          headers: {
            'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
          }
        })
        .then(response => {
          if (!response.ok) throw new Error('Failed to download PDF');
          
          // Store content disposition before consuming the response
          const contentDisposition = response.headers.get('content-disposition');
          return { blob: response.blob(), contentDisposition };
        })
        .then(data => {
          return data.blob.then(blob => {
            var url = window.URL.createObjectURL(blob);
            var a = document.createElement('a');
            a.href = url;

            const selectedCheckbox = document.querySelector('.js--statement-checkbox:checked');
            const invoiceNumber = selectedCheckbox ? selectedCheckbox.dataset.invoiceNumber : '';
            var filename = invoiceNumber ? `Statement_${invoiceNumber}.pdf` : "statement.pdf";
            
            if (data.contentDisposition) {
              var match = /filename[^;=\n]*=((['"]).*?\2|[^;\n]*)/.exec(data.contentDisposition);
              if (match && match[1]) {
                filename = match[1].replace(/['"]/g, '');
              }
            }

            a.download = filename;
            a.style.display = 'none';
            document.body.appendChild(a);
            a.click();
            window.URL.revokeObjectURL(url);
            document.body.removeChild(a);
            
            downloadButton.disabled = false;
          });
        })
        .catch(error => {
          console.error('Error:', error);
          alert('Error downloading the statement. Please try again.');
          downloadButton.disabled = false;
        });

        return;
      }

      event.preventDefault();
      const formData = new FormData();
      selectedIds.forEach(id => formData.append('statement_ids[]', id));

      fetch(form.action + '.json', {
        method: 'POST',
        body: formData,
        headers: {
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        }
      })
      .then(response => {
        if (!response.ok) throw new Error('Network response was not ok');
        return response.json();
      })
      .then(data => {
        if (data.pdfs && data.pdfs.length > 0) {
          data.pdfs.forEach((pdf, index) => {
            setTimeout(() => {
              const dataUrl = 'data:application/pdf;base64,' + pdf.data;
              const link = document.createElement('a');
              link.href = dataUrl;
              link.download = pdf.filename;
              link.style.display = 'none';
              document.body.appendChild(link);
              link.click();
              document.body.removeChild(link);
            }, index * 1000);
          });
        }

        downloadButton.disabled = false;
      })
      .catch(error => {
        console.error('Error:', error);
        alert('There was an error downloading the statements. Please try again.');
        downloadButton.disabled = false;
      });
    });
  }

  updateButtonState();
});
