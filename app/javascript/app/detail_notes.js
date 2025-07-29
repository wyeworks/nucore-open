/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
$(function() {
  const hiddenText = "More";
  const openText = "Less";

  return $('.js--toggleNote').on('click', function(e) {
    e.preventDefault();
    const $parent = $(this).parent();
    const text = $(this).text();
    $parent.find(".js--note").toggle();
    $parent.find(".js--truncatedNote").toggle();
    $(this).text(text === hiddenText ? openText : hiddenText);
  });
});
