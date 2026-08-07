import { Controller } from "@hotwired/stimulus"

// Submits the form this controller is attached to. Wire it up with
// `data-action="change->auto-submit#submit"` to turn any input into one that saves
// itself, and let the Turbo Stream response say what changed on the page.
export default class extends Controller {
  submit() {
    this.element.requestSubmit()
  }
}
