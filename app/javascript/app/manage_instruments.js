/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
$(function() {
  const target = '.edit_instrument #instrument_min_reserve_mins,.edit_instrument #instrument_max_reserve_mins';

  if ($(target).length) {
    $(target).bind('keyup mouseup', function() {
      const interval = $('#instrument_reserve_interval').val();

      if (($(this).val() % interval) === 0) {
        return $(this).removeClass('interval-error');
      } else {
        return $(this).addClass('interval-error');
      }
    });
  }

  $('#instrument_auto_cancel_mins').change(function(event) {
    const $warning_node = $(".js--auto_cancel_mins-zero-warning");
    const minutes = $(event.target).val() || 0;

    if (minutes > 0) {
      return $warning_node.hide();
    } else {
      return $warning_node.show();
    }
  });

  return $('#instrument_auto_cancel_mins').change();
});


$(function() {
  const pricingModeElement = document.querySelector(".js--pricing-mode");

  if (!pricingModeElement) {
    return;
  }

  pricingModeElement.addEventListener("change", function () {
    const dailyBookingRadioButton = document.querySelector(
      "#instrument_pricing_mode_schedule_rule_daily_booking_only"
    );

    if (!dailyBookingRadioButton) {
      return;
    }

    const dailyBooking = dailyBookingRadioButton.checked;

    document
      .querySelectorAll(".js--daily-booking")
      .forEach((element) => element.toggleAttribute("hidden", !dailyBooking));
    document
      .querySelectorAll(".js--normal-booking")
      .forEach((element) => element.toggleAttribute("hidden", dailyBooking));
  });
});
