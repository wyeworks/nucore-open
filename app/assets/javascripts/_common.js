$(document).ready(function() {
  if ($('#login') && $('#username')) {
    $('#username').focus();
  }

  $('.link_select').change(function(e) {
    window.location = this.value;
  });

  $('form#ajax_form').submit(function(e){
    e.preventDefault(); //Prevent the normal submission action
    var form = $(this);
    var submit = $("input[type='submit']",form);
    var submit_val = submit.val();
    submit.val("Please Wait...");
    submit.attr("disabled", true);
    jQuery.ajax({
      type: "get",
      data: form.serialize(),
      url:  form.attr('action'),
      timeout: 25000,
      success: function(r) {
        $('#result').html(r);
        submit.val(submit_val);
        submit.attr("disabled", false);
      },
      error: function() {
        $('#result').html('<p>There was an error retrieving results.  Please try again.</p>');
        submit.val(submit_val);
        submit.attr("disabled", false);
      }
    });
  });

  $('#content').click(function(e){
    var element = $(e.target);
    if (element.is('a') && element.parents('div.ajax_links').length == 1) {
      e.preventDefault(); //Prevent the normal action
      jQuery.ajax({
        url: element.attr('href'),
        timeout: 25000,
        success: function(r) {
          $('#result').html(r);
        },
        error: function() {
          $('#result').html('<p>There was an error retrieving results.  Please try again.</p>');
        }
      });
    } else {
      return;
    }
  });

  $('.sync_select').change(function(e) {
    var selected_value = this.value;
    $('.sync_select[name='+this.name+']').each(function(e) {
      this.value = selected_value;
    });
  });

  $('#filter_toggle').click(function(){
     $('#filter_container').toggle('fast');
   });

});

String.prototype.endsWith = function(suffix) {
  return this.indexOf(suffix, this.length - suffix.length) !== -1;
};
