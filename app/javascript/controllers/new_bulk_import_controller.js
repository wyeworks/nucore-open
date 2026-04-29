import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["help"];

  updateHelp(event) {
    this.helpTarget.src = `${this.baseUrl}?import_type=${event.target.value}`;
  }

  get baseUrl() {
    return this.helpTarget.dataset.baseUrl;
  }
}
