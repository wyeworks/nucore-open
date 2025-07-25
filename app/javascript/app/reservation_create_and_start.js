/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
$(function() {
  if ((typeof isBundle !== 'undefined' && isBundle !== null) && !isBundle && !ordering_on_behalf) {
    // Event triggered by ReservationTimeFieldAdjustor
    return $(".js--reservationUpdateCreateAndStart").on("reservation:times_changed", function(evt, reservation_time_data) {

      if (ctrlMechanism === "manual") { return; }
      if (!instrumentOnline) { return; }

      const now = new Date();
      const grace_time = now.clone().addMinutes(5);
      const picked = reservation_time_data.start;

      // change reservation creation button based on Reservation
      const text = picked.between(now, grace_time) ? "Create & Start" : "Create";
      return $("#reservation_submit").attr("value", text);
    });
  }
});
