/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
window.AccessoryPicker = class AccessoryPicker {
  constructor($form) {
    this.$form = $form;
    this.init_timeinput();
    this.init_checkboxes();
  }

  init_timeinput() {
    return this.$form.find('.timeinput').timeinput();
  }

  init_checkboxes() {
    const self = this;
    return this.$form.find('input[type=checkbox]').change(function() {
      return self.enable_elements(this);}).trigger('change');
  }

  enable_elements(checkbox) {
    const $checkbox = $(checkbox);
    const enabled = $checkbox.prop('checked');
    const $row = $checkbox.closest('.accessory-row');

    $row.toggleClass('disabled', !enabled);
    const $input = $row.find('input').not(checkbox).not('[type=hidden]');
    $input.prop('disabled', !enabled || ($input.data('always-disabled') === true));
    // use visibility instead of show/hide so it maintains the same spacing
    return $input.css('visibility', enabled ? 'visible' : 'hidden');
  }
};

class AccessoryPickerDialog {
  constructor($link) {
    this.load_dialog = this.load_dialog.bind(this);
    this.$link = $link;
    this.hide_tooltips();
    this.init_dialog_element();
    this.show_dialog();
    this.fade_out();
  }

  hide_tooltips() {
    if ($('.tip').length > 0) { return $('.tip').data('tooltipsy').hide(); }
  }

  init_dialog_element() {
    const self = this;

    this.dialog = $('#pick_accessories_dialog');

    // build dialog if necessary
    if (this.dialog.length === 0) {
      this.dialog = $('<div id="pick_accessories_dialog" class="modal hide fade" data-backdrop="static" role="dialog"/>');
      this.dialog.hide();
      $("body").append(this.dialog);
    }

    this.dialog.on('ajax:complete', 'form', (evt, xhr, status) => self.handle_response(evt, xhr, status));

    if (this.$link.data('refresh-on-cancel')) {
      this.dialog.on('hidden', () => window.location.reload());
    }

    return this.dialog.on('submit', 'form', () => self.toggle_buttons(false));
  }

  show_dialog() {
    const self = this;
    return $.ajax({
      url: this.$link.attr('href'),
      dataType: 'html',
      success(body) {
        return self.load_dialog(body);
      }
    });
  }

  load_dialog(body) {
    this.dialog.html(body).modal('show');
    this.picker = new AccessoryPicker($('#accessory-form'));
    return this.toggle_buttons(true);
  }

  toggle_buttons(value) {
    return this.dialog.find('input[type=submit]').prop('disabled', !value);
  }

  handle_response(e, xhr, status) {
    e.preventDefault();
    if (status === 'success') {
      this.dialog.modal('hide');
      return window.location.reload();
    } else {
      return this.load_dialog(xhr.responseText);
    }
  }


  fade_out() {
    if (!this.$link.hasClass('persistent')) { return this.$link.fadeOut(); }
  }
}


$(function() {
  $('body').on('click', '.has_accessories', function(evt) {
    let picker;
    evt.preventDefault();
    return picker = new AccessoryPickerDialog($(this));
  });

  return new AccessoryPicker($('.not-in-modal #accessory-form'));
});
