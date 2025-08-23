$(function() {
   $('.dismiss-notice').bind('ajax:complete', function(et, e) {
       $(this).parent().fadeOut();
       $('#notice-count').text("(" + $.trim(e.responseText) + ")");
   })
});
