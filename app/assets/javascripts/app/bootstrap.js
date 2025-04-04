/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
$(function() {
  $('[data-toggle=tooltip]').tooltip({html: true});

  // Make sure tooltips get initialzed on modal loading
  return $('body').on('modal:loaded', '.modal', function() {

    return $(this).find('[data-toggle=tooltip]').tooltip();
  });
});
