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

      this.timerTarget.textContent = `${hours.toString()} hours, ${minutes.toString()} minutes, ${seconds.toString()} seconds`
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
    
    teams.forEach((team, index) => {
      const row = tableBody.querySelector(`tr[data-team-id="${team.id}"]`)

      // Find the existing row, and update it. 
      if (row) {
        row.querySelector('[data-rank]').textContent = index + 1
        row.querySelector('[data-score]').textContent = team.score
        if (team.completed) {
          row.querySelector('[data-completed]').textContent = team.completed
          row.querySelector('[data-partially-completed]').textContent = team.partially_completed
          row.querySelector('[data-not-attempted]').textContent = team.not_attempted
        }
      }
    })
  }
}
