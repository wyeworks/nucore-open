import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["reservationDays", "destroy"]

  toggleReservationDays(event) {
    const value = event.target.value;
    let markForRemoval = false;

    if (value == "reservations") {
      this.reservationDaysTarget.classList.remove("hidden");
    } else if (value == "access_list") {
      this.reservationDaysTarget.classList.add("hidden");
    } else {
      this.reservationDaysTarget.classList.add("hidden");
      markForRemoval = true;
    }

    this.toggleRemoval(markForRemoval);
  }

  toggleRemoval(toRemove) {
    this.destroyTarget.value = toRemove;
  }
}
