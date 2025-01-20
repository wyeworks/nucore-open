/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */

//= require jquery-ui/widgets/autocomplete

const SubmissionPrimer = {
  handleCopy(event) {
    const row = $(event.target).parents("tr");

    if (row.length == 0) { return; }
    const primerName = row.find(".js--primerName").val()

    row.nextAll(":visible").find(".js--primerName").val(primerName);
  },
  setupCopyCallback(element) {
    $(element).on("click", this.handleCopy);
  },
  setupAutocomplete(element) {
    $(element).catcomplete({
      delay: 0,
      minLength: 0,
      source: corePrimers.map((primerName) => ({ label: primerName, category: "Core Primers" })),
    })
    $(element).focus(function () {
      $(this).catcomplete("search", "");
    });
  }
};

(function() {
  /**
   * Catcomplete implementation taken from jquery-ui documentation:
   * https://jqueryui.com/autocomplete/#categories
   */
  $.widget( "custom.catcomplete", $.ui.autocomplete, {
    _create: function() {
      this._super();
      this.widget().menu( "option", "items", "> :not(.ui-autocomplete-category)" );
    },
    _renderMenu: function( ul, items ) {
      let that = this, currentCategory = "";

      $.each( items, function( _index, item ) {
        let li;
        if ( item.category != currentCategory ) {
          ul.append( "<li class='ui-autocomplete-category'><strong>" + item.category + "</strong></li>" );
          currentCategory = item.category;
        }
        li = that._renderItemData( ul, item );
        if ( item.category ) {
          li.attr( "aria-label", item.category + " : " + item.label );
        }
      });
    }
  });
  $(document).ready(function() {
    SubmissionPrimer.setupAutocomplete($(".js--primerName"));
    SubmissionPrimer.setupCopyCallback($(".js--copyPrimerNameDown"));
  });
}());

$(() => $(document).on("fields_added.nested_form_fields", function(event) {
  const sangerSequencingForm = $("form.edit_sanger_sequencing_submission");
  if (!(sangerSequencingForm.length > 0)) { return; }
  const row = $(event.target);
  const customerSampleIdField = row.find(".js--customerSampleId");
  const prevSamplePrimerName = row.prevAll(":visible:first").find(".js--primerName").val();

  SubmissionPrimer.setupCopyCallback(row);

  customerSampleIdField.prop("disabled", true).val("Loading...");
  $.post(sangerSequencingForm.data("create-sample-url")).done(function(sample) {
    customerSampleIdField.prop("disabled", false).val(sample.customer_sample_id);
    row.find(".js--sampleId").val(sample.id).text(sample.id);

    const primerInputEl = row.find(".js--primerName");
    SubmissionPrimer.setupAutocomplete(primerInputEl);

    if (prevSamplePrimerName) {
      primerInputEl.val(prevSamplePrimerName);
    }
  });
}));
