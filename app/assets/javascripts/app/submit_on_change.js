/**
  * By adding the class `js--submit-on-change` to a form
  * it will submit on any input change.
  *
  * i.e. to filter forms
  */
$(function () {
  function setupSubmitOnChange(form) {
    console.log("Setup js--submit-on-change")
    form.addEventListener("change", function() {
      form.submit()
    });
  }

  document.addEventListener("DOMContentLoaded", function() {
    document
      .querySelectorAll("form.js--submit-on-change")
      .forEach(setupSubmitOnChange)
    console.log("Setup js--submit-on-change")
  })
}());
