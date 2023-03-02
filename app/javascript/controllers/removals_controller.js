import { Controller } from "@hotwired/stimulus"

// Drops a flash message from the DOM once its fade-out animation ends, so
// stale messages do not pile up under Turbo navigation.
export default class extends Controller {
  remove() {
    this.element.remove()
  }
}
