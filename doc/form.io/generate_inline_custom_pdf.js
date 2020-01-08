// Generate In-Line Custom PDF within Current Form
// Replace [token_id]
var pdfFileName = data.orderedForUsernname && data.nucoreOrderNumber ? data.orderedForUsernname + '-' + data.nucoreOrderNumber : 'document';
var fileToken = '[token_id]'; // PDF token

instance.label = 'Print Tag'; // change label
instance.redraw();
// Create instance using same pdf as nested form
var pdf = new Formio([form_id]);

// change submission state to save it as draft
submission.state = 'draft';
pdf.loadForm().then(function(res) {
  // create pdf url download
  var parentProjectId = res.project
  var downloadUrl = 'https://files.form.io/pdf/' +
    parentProjectId +
    '/file/pdf/download?format=pdf';
  var pdfSubmission = {
    data: {}
  };
  res.components.forEach(function(component) {
    console.log(component.key, data[component.key]);
    if (component.input && data[component.key]) {
      pdfSubmission.data[component.key] = data[component.key];
    }
  });
  console.log(pdfSubmission);
  var requestJson = JSON.stringify({
    form: res,
    submission: pdfSubmission
  });
  // getting file
  fetch(downloadUrl, {
      method: 'POST',
      body: requestJson,
      headers: {
        'Content-Type': 'application/json',
        'x-file-token': fileToken
      }
    })
    .then(function(res) {
      // creating blob
      return res.blob();
    })
    .then(function(blob) {
      // creating file
      var reader = new FileReader();

      reader.onload = function() {
        //creating link
        var downloadLink = document.createElement('a');
        downloadLink.href = reader.result;
        downloadLink.download = pdfFileName + '.pdf';
        //simulating click to download
        downloadLink.click();
        instance.label = instance.originalComponent.label;
        instance.redraw();
      };

      reader.readAsDataURL(blob);
    })
    .catch(function(err) {
      //  errors
      alert('Error while generating PDF');
      instance.label = instance.originalComponent.label;
      instance.redraw();
    });
});
