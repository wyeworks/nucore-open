/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
window.AjaxModal = class AjaxModal {
  constructor(link_selector, modal_selector, options) {
    let $modal;
    this.form_prepare = this.form_prepare.bind(this);
    this.form_success = this.form_success.bind(this);
    this.form_error = this.form_error.bind(this);
    this.reload = this.reload.bind(this);
    this.link_selector = link_selector;
    this.modal_selector = modal_selector;
    if (options == null) { options = {}; }
    this.options = options;
    const $link = $(this.link_selector);
    this.$modal = ($modal = $(this.modal_selector));
    if (this.$modal.length === 0) {
      this.$modal = ($modal = this.build_new_modal());
    }

    const success = this.options['success'];
    const {
      form_prepare
    } = this;

    this.loading_text = this.options.loading_text || 'Loading...';

    const self = this;

    $link.click(function(e) {
      e.preventDefault();
      $modal.modal('show');
      $modal.data('href', $(this).attr('href'));
      $modal.data('modalObject', self);
      return self.reload();
    });
  }

  static on_show(fn) {
    return $("body").on("modal:loaded", ".modal", fn);
  }

  form_prepare() {
    const self = this;

    const form = this.$modal.find('form');
    form.bind('submit', () => form.find('input[type=submit]').prop('disabled', true));

    form.bind('ajax:error', this.form_error);
    form.bind('ajax:success', (evt, xhr, c) => self.form_success(xhr.responseText));

    this.$modal.trigger('modal:loaded');

    const success = this.options['success'];
    if (success != null) { return success(self); }
  }

  form_success(body) {
    return window.location.reload();
  }

  form_error(evt, xhr) {
    this.$modal.html(xhr.responseText);
    return this.form_prepare();
  }

  build_new_modal() {
    const modal = $('<div class="modal fade" data-backdrop="static"></div>');
    modal.attr('id', this.modal_selector.replace('#', ''));
    return modal.appendTo('body');
  }

  reload() {
    const {
      $modal
    } = this;
    const self = this;
    $modal.html(`<div class='modal-body'><h3>${this.loading_text}</h3></div>`);
    return $.ajax({
      url: $modal.data('href'),
      dataType: 'html',
      success(body) {
        $modal.html(body);
        return self.form_prepare();
      }
    });
  }
};
