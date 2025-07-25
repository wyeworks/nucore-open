$(function(){

  // ---------------------------------------------------------------------------
  // Toggle affiliate
  // ---------------------------------------------------------------------------
  function toggleAffiliate() {
    $(".js--affiliate_other").toggle($(".js--affiliate:visible option:selected").data("subaffiliatesEnabled") || false)
  }

  $(".js--affiliate").change(function() {
    toggleAffiliate();
  });

  toggleAffiliate();

  // ---------------------------------------------------------------------------
  // Date picker
  // ---------------------------------------------------------------------------
  $(".datepicker").datepicker({minDate:+0, maxDate:"+3y", dateFormat: "mm/dd/yy"});

  // ---------------------------------------------------------------------------
  // Autotab
  // ---------------------------------------------------------------------------
  $(".account_number_field :input[maxlength]").keyup(function(evt) {
    $this = $(this);
    // if it is a number key
    if (evt.keyCode >= 96 && evt.keyCode <= 105) {
      if ($this.val().length >= $this.attr("maxlength")) {
        var inputs = $this.closest("form").find(":input");
        inputs.eq( inputs.index(this)+ 1 ).focus();
      }
    }
  });
});
