$(function() {
  var checkbox = $(".js--umass-username-toggle");
  var usernameField = $(".js--umass-username");

  checkbox.change(function(evt) {
    usernameField.toggle(!evt.target.checked)
  }).trigger("change");
});
