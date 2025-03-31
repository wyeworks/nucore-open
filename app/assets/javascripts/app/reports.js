/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
class TabbableReports {
  constructor($element) {
    this.$element = $element;
    if (!(this.$element.length > 0)) { return; }
    this.$tabs = this.$element.find('#tabs');
    this.init_tabs();
    this.init_form();
    this.init_pagination();
    this.init_export_all_handler();
  }

  export_all_link() {
    return $(".js--exportRaw");
  }

  update_parameters() {
    this.update_href($(this.current_tab()));
    return this.refresh_tab();
  }

  refresh_tab() {
    const index = this.$tabs.tabs('option', 'active');
    const current_tab = this.$tabs.find('[role=tab]')[index];
    return this.$tabs.tabs('load', index);
  }

  current_tab() {
    let current_tab;
    const index = this.$tabs.tabs('option', 'active');
    return current_tab = this.$tabs.find('[role=tab]')[index];
  }

  init_tabs() {
    this.$tabs.find('a').each(function(_, tab_link) {
      const $tab_link = $(tab_link);
      return $tab_link.parent('li').data('base-href', $tab_link.attr('href'));
    });

    return this.$tabs.tabs({
      active: window.activeTab,
      beforeActivate: (_, ui) => {
        // if there was an old error message, fade it out now
        $('#error-msg').fadeOut();
        this.update_href(ui.newTab);
        return true;
      },

      beforeLoad(_, ui) {
        if (this.in_flight_xhr != null) { this.in_flight_xhr.abort(); }
        this.in_flight_xhr = ui.jqXHR;

        // Show a loading message so the user sees immediate feedback
        // that their action is being applied
        ui.panel.html('<span class="updating"></span> Loading...');
        ui.ajaxSettings.dataType = 'text/html';

        ui.jqXHR.always(() => { if (this.in_flight_xhr === ui.jqXHR) { return this.in_flight_xhr = null; } });

        return ui.jqXHR.error(function(xhr, status, error) {
          // don't show error message if the user aborted the ajax request
          if (status !== 'abort') {
            return $('#error-msg').
              html('Sorry, but the tab could not load. Please try again soon.').
              show();
          }
        });
      },

      load: (_, ui) => {
        this.update_export_all_link_visibility(ui.panel);
        this.fix_bad_dates(ui.panel);
        return this.update_export_urls();
      }
    });
  }

  build_query_string() {
    return "?" + this.$element.serialize();
  }

  tab_url(tab) {
    return $(tab).data('base-href') + this.build_query_string();
  }

  init_form() {
    if ($('#status_filter').length) { $('#status_filter').chosen(); }
    $('.datepicker').datepicker();
    return this.$element.find(':input').change(() => this.update_parameters());
  }

  update_href(tab) {
    return tab.find('a').attr('href', this.tab_url(tab));
  }

  // Make sure to update the date params in case they were empty or invalid
  fix_bad_dates(panel) {
    $('#date_start').val($(panel).find('.updated_values .date_start').text());
    return $('#date_end').val($(panel).find('.updated_values .date_end').text());
  }

  init_pagination() {
    return $(document).on('click', '.pagination a', evt => {
      evt.preventDefault();
      $(this.current_tab()).find('a').attr('href', $(evt.target).attr('href'));
      return this.refresh_tab();
    });
  }

  update_export_all_link_visibility(panel) {
    if ($(panel).find('.export_raw').data('visible')) {
      return this.export_all_link().show();
    } else {
      return this.export_all_link().hide();
    }
  }

  update_export_urls() {
    const url = this.tab_url(this.current_tab());
    $('#export').attr('href', url + '&export_id=report&format=csv');
    return this.export_all_link().attr("href", this.export_all_link().data("original-url") + this.build_query_string());
  }

  init_export_all_handler() {
    this.$emailToAddressField = $('.js--exportRawEmailField');
    return this.export_all_link()
      .attr("data-remote", true)
      .data("original-url", this.export_all_link().attr("href"))
      .click(event => this.export_all_email_confirm(event));
  }

  export_all_email_confirm(event) {
    event.preventDefault();

    const new_to = prompt(
      'Have the report emailed to this address:',
      this.$emailToAddressField.val()
    );

    if (new_to) {
      this.$emailToAddressField.val(new_to);
      this.update_export_urls();
      // Actual sending handled by remote: true
      return Flash.info(`A report is being prepared and will be emailed to ${new_to} \
when complete`);
    } else {
      return false; // prevent handling by remote: true
    }
  }
}

$(() => window.report = new TabbableReports($('#refresh-form')));
