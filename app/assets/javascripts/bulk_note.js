$(document).ready(function() {
  var bulkNoteCheckbox = $("#bulk_note_checkbox");
  var bulkNoteInput = $("#bulk-note-input");
  bulkNoteInput.hide()
  var rowNoteInputs = $(".row-note-input")

  bulkNoteCheckbox.change(function(e){
    if (bulkNoteCheckbox[0].checked === true){
      bulkNoteInput.show();
      rowNoteInputs.hide();
    } else if (bulkNoteCheckbox[0].checked === false) {
      bulkNoteInput.hide();
      rowNoteInputs.show();
    }
  })
})
