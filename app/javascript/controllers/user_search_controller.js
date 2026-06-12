import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["searchInput", "searchResults", "selectedUsers"]
  static values = { searchUrl: String }

  search() {
    const term = this.searchInputTarget.value.trim()
    if (term.length === 0) return

    const resultsUrl = `${this.searchUrlValue}?search_term=${encodeURIComponent(term)}`;
    this.searchResultsTarget.src = resultsUrl;
  }

  addUser({ target } = event) {
    if (this.selectedIds.includes(target.dataset.userId)) { return; }

    const li = event.currentTarget.closest("li")
    const input = li.querySelector("input")
    const addBtn = li.querySelector("button")

    input.disabled = false
    addBtn.classList.remove("btn-primary")
    addBtn.classList.add("btn-danger")
    addBtn.textContent = addBtn.dataset.removeLabel || "Remove"
    addBtn.dataset.action = "click->user-search#removeUser"

    this.selectedUsersTarget.appendChild(li)
  }

  removeUser(event) {
    event.currentTarget.closest("li").remove()
  }

  get selectedIds() {
    return [...this.selectedUsersTarget.querySelectorAll("li")].map(
      li => li.dataset.userId
    )
  }
}
