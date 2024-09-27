import { Controller } from "@hotwired/stimulus"
import { connectToScoringChannel } from "../channels/scoring_channel"

export default class extends Controller {
  static targets = ["regularPoints", "bonusPoints", "status", "totalPoints", "row", "searchInput", "sortSelect"]
  static values = { userId: Number }

  connect() {
    this.previousValues = {}

    connectToScoringChannel(this, this.userIdValue);
  }

  updateScore(event) {
    const input = event.target
    const challengeId = input.dataset.challengeId
    const userId = input.dataset.userId
    const regularPoints = this.getRegularPoints(challengeId, userId)
    const bonusPoints = this.getBonusPoints(challengeId, userId)

    this.savePreviousValue(input)
    this.sendUpdateRequest(challengeId, userId, regularPoints, bonusPoints, input)
  }

  undoRegularPoints(event) {
    const button = event.target
    const challengeId = button.dataset.challengeId
    const userId = button.dataset.userId
    const input = this.getRegularPointsInput(challengeId, userId)
    
    if (this.previousValues[input.id]) {
      input.value = this.previousValues[input.id]
      this.updateScore({ target: input })
    }
  }

  undoBonusPoints(event) {
    const button = event.target
    const challengeId = button.dataset.challengeId
    const userId = button.dataset.userId
    const input = this.getBonusPointsInput(challengeId, userId)
    
    if (this.previousValues[input.id]) {
      input.value = this.previousValues[input.id]
      this.updateScore({ target: input })
    }
  }

  awardFullPoints(event) {
    const button = event.target
    const challengeId = button.dataset.challengeId
    const userId = button.dataset.userId
    const regularPointsInput = this.getRegularPointsInput(challengeId, userId)
    const pointsToWin = regularPointsInput.dataset.pointsToWin

    regularPointsInput.value = pointsToWin
    this.updateScore({ target: regularPointsInput })
  }

  sendUpdateRequest(challengeId, userId, regularPoints, bonusPoints, input) {
    fetch('/scoring/update', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({ challenge_id: challengeId, user_id: userId, regular_points: regularPoints, bonus_points: bonusPoints })
    })
    .then(response => response.json())
    .then(data => {
      if (data.status === 'success') {
        // This doesn't actually flash the elements because there are no changes to the values anymore, 
        // however, good to run it to update the total points and status.
        this.updateUI(challengeId, userId, data.result, 'green')
        this.flashElement(input, 'green');
      } else {
        console.error('Error updating score:', data.errors)
      }
    })
    .catch(error => console.error('Error:', error))
  }

  updateUI(challengeId, userId, result, colour) {
    const regularPointsInput = this.getRegularPointsInput(challengeId, userId)
    const bonusPointsInput = this.getBonusPointsInput(challengeId, userId)
    const statusElement = this.getStatusElement(challengeId)
    
    const updatedElements = []

    if (regularPointsInput.value !== result.regular_points.toString()) {
      regularPointsInput.value = result.regular_points
      updatedElements.push(regularPointsInput)
    }

    if (bonusPointsInput.value !== result.bonus_points.toString()) {
      bonusPointsInput.value = result.bonus_points
      updatedElements.push(bonusPointsInput)
    }

    statusElement.textContent = result.status
      
    updatedElements.forEach(element => this.flashElement(element, colour))

    this.updateTotalPoints()
  }

  updateTotalPoints() {
    const totalPoints = Array.from(this.regularPointsTargets).reduce((sum, input) => {
      return sum + parseInt(input.value || 0)
    }, 0) + Array.from(this.bonusPointsTargets).reduce((sum, input) => {
      return sum + parseInt(input.value || 0)
    }, 0)

    this.totalPointsTarget.textContent = totalPoints
  }

  flashElement(element, colour) {
    element.classList.add('flash-' + colour);
    setTimeout(() => {
      element.classList.remove('flash-' + colour);
    }, 1000);
  }

  savePreviousValue(input) {
    if (!this.previousValues[input.id]) {
      this.previousValues[input.id] = input.value
    }
  }

  getRegularPoints(challengeId, userId) {
    return this.getRegularPointsInput(challengeId, userId).value
  }

  getBonusPoints(challengeId, userId) {
    return this.getBonusPointsInput(challengeId, userId).value
  }

  getRegularPointsInput(challengeId, userId) {
    return this.regularPointsTargets.find(target =>
      target.dataset.challengeId === challengeId && target.dataset.userId === userId
    )
  }

  getBonusPointsInput(challengeId, userId) {
    return this.bonusPointsTargets.find(target =>
      target.dataset.challengeId === challengeId && target.dataset.userId === userId
    )
  }

  getStatusElement(challengeId) {
    return this.statusTargets.find(target => target.dataset.challengeId === challengeId)
  }

  search() {
    const query = this.searchInputTarget.value.toLowerCase()

    this.rowTargets.forEach(row => {
      const text = row.textContent.toLowerCase()
      row.style.display = text.includes(query) ? "" : "none"
    })
  }

  sort() {
    const column = this.sortSelectTarget.value
    const rows = Array.from(this.rowTargets)

    rows.sort((a, b) => {
      const aValue = a.querySelector(`[data-column="${column}"]`).textContent
      const bValue = b.querySelector(`[data-column="${column}"]`).textContent
      return aValue.localeCompare(bValue)
    })
  
    const tbody = this.element.querySelector('tbody')
    rows.forEach(row => tbody.appendChild(row))
  }

  handleWebSocketUpdate(data) {
    if (data.user_id == this.userIdValue) {
      this.updateUI(data.challenge_id, data.user_id, data, "blue");
    } else {
      console.log("WARNING: Received data for wrong user:", data, "; data.user_id: ", data.user_id, "; this.userIdValue: ", this.userIdValue);
    }
  }
}