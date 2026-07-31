$(function() {
	$("select[multiple]").chosen({ width: "100%" });
});

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
