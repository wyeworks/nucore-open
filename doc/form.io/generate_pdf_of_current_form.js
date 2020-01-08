// Generate PDF of Current Form View
// Replace `[token_id]` and `[form_id]`
var pdfFileName = data.orderedForUsernname && data.nucoreOrderNumber ? data.orderedForUsernname + '-' + data.nucoreOrderNumber : 'document';
var fileToken = '[token_id]'; // PDF token
var currentForm = '[form_id]';

instance.label = 'Generating Preview'; // change button label
instance.redraw();
// change submission state to draft.
submission.state = 'draft';
fetch(currentForm, {
    method: 'GET',
    headers: {
      'Content-Type': 'application/json'
    }
  })
  .then(function(data) {
    //reciving data via Fetch
    return data.json();
  })
  .then(function(res) {
    // Create pdf file link
    var parentProjectId = res.project
    var downloadUrl = 'https://files.form.io/pdf/' +
      parentProjectId +
      '/file/pdf/download?format=pdf';

    // Build the submission to preview
    var requestJson = JSON.stringify({
      form: res,
      submission: {
        data: data
      }
    });
    // Submit the form as draft
    fetch(downloadUrl, {
        method: 'POST',
        body: requestJson,
        headers: {
          'Content-Type': 'application/json',
          'x-file-token': fileToken
        }
      })
      .then(function(response) {
        //creates a blob
        instance.label = 'Downloading PDF'; // change button label
        instance.redraw();
        return response.blob();

      })
      .then(function(blob) {
        // Read the file
        var reader = new FileReader();

        reader.onload = function() {
          // Create an Element to download pdf
          var downloadLink = document.createElement('a');
          downloadLink.href = reader.result;
          downloadLink.download = pdfFileName + '.pdf';
          downloadLink.click();
          instance.label = instance.originalComponent.label;
          instance.redraw();
          instance.label = 'Saving'; // change button label
          instance.redraw();
          form.submit();
        };

        reader.readAsDataURL(blob);
      })
      .catch(function(err) {
        alert('Error while generating PDF');
        instance.label = instance.originalComponent.label;
        instance.redraw();
      });

  });
