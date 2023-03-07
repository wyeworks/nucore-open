/***
 * Logic for handling submitting forms to Form.io
 * Shared by new and edit views
 *
 * form - Formio form object
 * surveyUrl - url of the form within Form.io (not NUCore)
 * surveyCompleteUrl - NUCore url to post to after data has been submitted to Form.io
 * prefillData - only be set for new form submissions (not editing)
***/

function handleFormioSubmission(form, surveyUrl, surveyCompleteUrl, prefillData) {
  if (prefillData) {
    form.submission = { data: prefillData };
  }

  form.on('submitDone', function(submission) {
    if (prefillData) {
      // Prevent double-clicks from breaking things
      if (!surveyUrl.includes(submission._id)) {
        surveyUrl = surveyUrl + submission._id;
      }
    }
    var orderDetailData = {
      order_detail: submission.data,
      survey_url: surveyUrl,
      survey_edit_url: surveyUrl
    }

    jQuery.ajax({
      type: "post",
      data: orderDetailData,
      url:  surveyCompleteUrl,
      timeout: 25000
    });
  });
};
