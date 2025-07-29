/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
$(function() {

  // Look at the main navigation bar to see if we're in orders or reservations
  const currentSection = function() {
    const active_tab = $('.navbar-static-top .active').attr('id');
    if (active_tab == null) { return; }

    if (active_tab.indexOf('reservations') > -1) {
      return 'reservations';
    // TODO: Using this engine-referencing condition here is a stopgap to avoid
    //       removal of the now-defunct tab-count ajax reloading.
    } else if (active_tab.indexOf('occupancies') > -1) {
      return 'occupancies';
    } else {
      return 'orders';
    }
  };

  const loadTabCounts = function() {
    const tabs = [];
    $('li:not(.active) .js-tab-counts').each(function() {
      if (this.id !== "") {
        tabs.push(this.id);
        // Add a spinner
        return $(this).append('<span class="updating"></span>');
      }
    });

    if (tabs.length > 0) {
      let base = FACILITY_PATH;

      const section = currentSection();
      if (!section) { return; }

      base += `/${section}/`;

      return $.ajax({
        url: base + 'tab_counts',
        dataType: 'json',
        data: { tabs },
        success(data, textStatus, xhr) {
          return (() => {
            const result = [];
            for (var i of Array.from(tabs)) {
              var element = $(`.js-tab-counts#${i} .updating`);
              element.removeClass('updating');
              if (data[i] != null) { result.push(element.text(`(${data[i]})`).addClass('updated')); } else {
                result.push(undefined);
              }
            }
            return result;
          })();
        }
      });
    }
  };

  return loadTabCounts();
});
