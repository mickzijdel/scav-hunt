import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tableBody", "timer"]
  static values = {
    updateUrl: String,
    updateInterval: Number,
    endTime: String
  }

  connect() {
    this.updateScoreboard()
    this.startUpdateTimer()
    this.startCountdownTimer()
  }

  disconnect() {
    this.stopUpdateTimer()
    this.stopCountdownTimer()
  }

  startUpdateTimer() {
    this.updateTimerId = setInterval(() => {
      this.updateScoreboard()
    }, this.updateIntervalValue)
  }

  stopUpdateTimer() {
    if (this.updateTimerId) {
      clearInterval(this.updateTimerId)
    }
  }

  startCountdownTimer() {
    // TODO: Set the end time value.
    this.endTimeValue = new Date("2024-09-28T15:00:00").toISOString()
    
    this.countdownTimerId = setInterval(() => {
      this.updateCountdownTimer()
    }, 1000)
  }

  stopCountdownTimer() {
    if (this.countdownTimerId) {
      clearInterval(this.countdownTimerId)
    }
  }

  updateCountdownTimer() {
    const now = new Date().getTime()
    const endTime = new Date(this.endTimeValue).getTime()
    const timeLeft = endTime - now

    if (timeLeft < 0) {
      this.timerTarget.textContent = "Time's up!"
      this.stopCountdownTimer()
    } else {
      const hours = Math.floor(timeLeft / (1000 * 60 * 60))
      const minutes = Math.floor((timeLeft % (1000 * 60 * 60)) / (1000 * 60))
      const seconds = Math.floor((timeLeft % (1000 * 60)) / 1000)

      this.timerTarget.textContent = `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`
    }
  }

  async updateScoreboard() {
    try {
      const response = await fetch(this.updateUrlValue)
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }
      const teams = await response.json()
      this.updateTable(teams)
    } catch (error) {
      console.error("Error updating scoreboard:", error)
    }
  }

  updateTable(teams) {
    const tableBody = this.tableBodyTarget
    tableBody.innerHTML = ''

    teams.forEach((team, index) => {
      const row = tableBody.insertRow()
      row.insertCell().textContent = index + 1
      row.insertCell().textContent = team.name
      row.insertCell().textContent = team.score

      if (team.completed) {
        row.insertCell().textContent = team.completed
        row.insertCell().textContent= team.partially_completed
        row.insertCell().textContent = team.not_attempted
      }
    })
  }
}
