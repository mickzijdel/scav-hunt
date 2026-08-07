import { Controller } from "@hotwired/stimulus"

// Ticks a deadline down to zero, once a second.
//
// The remaining time is also rendered server-side, so the page is already correct
// before this controller ever runs; all it does is keep the number moving. This is
// the one piece of the scoreboard that genuinely needs JavaScript -- everything
// else on the page arrives over a Turbo Stream.
export default class extends Controller {
  static values = { endTime: String }

  #timer

  connect() {
    this.#timer = setInterval(() => this.#tick(), 1000)
    this.#tick()
  }

  disconnect() {
    this.#stop()
  }

  // Also fires on initialize, and again whenever a morph brings a new deadline in.
  endTimeValueChanged() {
    this.#tick()
  }

  #tick() {
    const endTime = Date.parse(this.endTimeValue)

    if (isNaN(endTime)) return

    const timeLeft = endTime - Date.now()

    if (timeLeft < 0) {
      this.element.textContent = "Time's up!"
      this.#stop()
    } else {
      const hours = Math.floor(timeLeft / 3600000)
      const minutes = Math.floor(timeLeft / 60000) % 60
      const seconds = Math.floor(timeLeft / 1000) % 60

      this.element.textContent = `${hours}h ${minutes}m ${seconds}s`
    }
  }

  #stop() {
    clearInterval(this.#timer)
    this.#timer = null
  }
}
