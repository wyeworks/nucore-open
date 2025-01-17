/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
window.vue_sanger_sequencing_bootstrap = function() {
  Vue.component("vue-sanger-sequencing-well-plate-editor-app", window.vue_sanger_sequencing_well_plate_editor_app);
  Vue.component("vue-sanger-sequencing-well-plate-displayer-app", window.vue_sanger_sequencing_well_plate_displayer_app);
  Vue.component("vue-sanger-sequencing-well-plate", window.vue_sanger_sequencing_well_plate);

  window.vueBus = new Vue;

  return new Vue({
    el: "body"});
};
