import { Controller } from "@hotwired/stimulus"

const DURATION = 1000

// Briefly highlights an element that a Turbo Stream has just re-rendered, so a
// change does not appear out of nowhere: green when the viewer made it themselves,
// blue when it arrived from somebody else. The element is fresh out of the stream,
// so connect() firing once per replacement is exactly the trigger we want.
export default class extends Controller {
  static values = { updatedBy: Number }

  #timer
  #colour

  connect() {
    this.#colour = this.updatedByValue === this.#currentUserId ? "flash-green" : "flash-blue"

    this.element.classList.add(this.#colour)
    this.#timer = setTimeout(() => this.element.classList.remove(this.#colour), DURATION)
  }

  disconnect() {
    clearTimeout(this.#timer)
    this.element.classList.remove(this.#colour)
  }

  get #currentUserId() {
    return Number(document.body.dataset.currentUserId)
  }
}
