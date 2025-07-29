$(function() {
	$("select[multiple]").chosen();

  $(".datepicker").each(function() {
    var datepickerParams = {};
    if ($(this).hasClass('in_past')) datepickerParams.maxDate = new Date();
    $(this).datepicker(datepickerParams);
  });
	// call trigger("change") to make sure that it updates on page load
	$(".datepicker[name=start_date]").change(DatePickerRange.updateEndMaxDate).trigger("change");
	$(".datepicker[name=end_date]").change(DatePickerRange.updateStartMinDate).trigger("change");



});

var DatePickerRange = {
	updateEndMaxDate: function() {
		$val = $(this).val();
		if ($val) {
			var start = Date.parse($val);
			$(".datepicker[name=end_date]").datepicker("option", {minDate: start });
		}
	},
	updateStartMinDate: function() {
		$val = $(this).val();
		if ($val) {
			var end = Date.parse($val);
			$(".datepicker[name=start_date]").datepicker("option", {maxDate: end});
		}
	}

}

$(function() {
	$("#facilities").change(function() {
		var facilitiesValues = $(this).val();
		if (facilitiesValues == null || facilitiesValues.length == 0) {
			$("#products option, #order_statuses option").each(function() {
				$(this).removeAttr("disabled");
			});
		} else {
			$("#products option, #order_statuses option").each(function() {
				// If the option doesn't have a facility or the facility is in the list of values
        if (!$(this).is("[data-facility]") || $.inArray($(this).attr("data-facility"), facilitiesValues) > -1) {
					$(this).removeAttr("disabled");
				} else {
					$(this).attr("disabled", "disabled").removeAttr("selected");
				}
			});
		}
		$("#products, #order_statuses").trigger("chosen:updated")
	});
});
