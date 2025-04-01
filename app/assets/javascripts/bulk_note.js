$(document).ready(function() {
  var bulkNoteCheckbox = $('input[name="bulk_note_checkbox"]');
  var bulkNoteInput = $("#bulk-note-input");
  var rowNoteInputs = $(".row-note-input input")

  bulkNoteInput.hide();
  bulkNoteCheckbox.change(function(event){
    if (event.target.checked){
      bulkNoteInput.show();
      rowNoteInputs.prop('disabled', true);
    } else {
      bulkNoteInput.hide();
      rowNoteInputs.prop('disabled', false);
    }
  })
})
