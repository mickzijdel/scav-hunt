import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["regularPoints", "bonusPoints", "status", "totalPoints"]

  connect() {
    this.previousValues = {}
  }

  updateScore(event) {
    const input = event.target
    const challengeId = input.dataset.challengeId
    const userId = input.dataset.userId
    const regularPoints = this.getRegularPoints(challengeId, userId)
    const bonusPoints = this.getBonusPoints(challengeId, userId)

    this.savePreviousValue(input)
    this.sendUpdateRequest(challengeId, userId, regularPoints, bonusPoints)
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

  sendUpdateRequest(challengeId, userId, regularPoints, bonusPoints) {
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
        this.updateUI(challengeId, userId, data.result)
      } else {
        console.error('Error updating score:', data.errors)
      }
    })
    .catch(error => console.error('Error:', error))
  }

  updateUI(challengeId, userId, result) {
    const regularPointsInput = this.getRegularPointsInput(challengeId, userId)
    const bonusPointsInput = this.getBonusPointsInput(challengeId, userId)
    const statusElement = this.getStatusElement(challengeId)

    regularPointsInput.value = result.regular_points
    bonusPointsInput.value = result.bonus_points
    statusElement.textContent = result.status

    // TODO: Either flash the whole row, or just the element that was updated, but not both.
    this.flashElement(regularPointsInput)
    this.flashElement(bonusPointsInput)
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


  flashElement(element) {
    element.classList.add('flash-green')
    setTimeout(() => {
      element.classList.remove('flash-green')
    }, 1000)
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
}