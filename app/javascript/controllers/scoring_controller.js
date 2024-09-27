import { Controller } from "@hotwired/stimulus"
import { connectToScoringChannel } from "../channels/scoring_channel"

export default class extends Controller {
  static targets = ["regularPoints", "bonusPoints", "status", "totalPoints"]
  // userId is the team, currentUserId is the scorer.
  // using userId is most consistent, but a bit confusing because it's about the team.
  static values = { userId: Number, currentUserId: Number }

  connect() {
    this.previousValues = {}
    this.websocketConnected = false

    connectToScoringChannel(this, this.userIdValue, (connected) => {
      this.websocketConnected = connected
    });
  }

  updateScore(event) {
    const input = event.target
    const challengeId = input.dataset.challengeId
    const userId = input.dataset.userId
    const regularPoints = this.getRegularPoints(challengeId, userId)
    const bonusPoints = this.getBonusPoints(challengeId, userId)

    this.savePreviousValue(input)

    const data = { 
      challenge_id: challengeId, 
      user_id: userId, 
      regular_points: regularPoints, 
      bonus_points: bonusPoints 
    }

    // Use websockets if connected, because they are way faster. Otherwise use a fetch request.
    if (this.websocketConnected) {
      this.sendUpdateViaWebSocket(data)
    } else {
      this.sendUpdateRequest(data)
    }
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

  sendUpdateViaWebSocket(data) {
    this.scoringChannel.send(data)
  }

  sendUpdateRequest(sendData) {
    fetch('/scoring/update', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify(sendData)
    })
    .then(response => response.json())
    .then(data => {
      if (data.status === 'success') {
        this.updateUI(data.result)
      } else {
        console.error('Error updating score:', data.errors)
      }
    })
    .catch(error => console.error('Error:', error))
  }

  updateUI(result) {
    const regularPointsInput = this.getRegularPointsInput(result.challenge_id.toString(), result.user_id.toString())
    const bonusPointsInput = this.getBonusPointsInput(result.challenge_id.toString(), result.user_id.toString())
    const statusElement = this.getStatusElement(result.challenge_id.toString())

    const updatedElements = []
    let colour = "blue";

    // If the result was updated by the current user, flash all elements and in green.
    console.log("this.currentUserIdValue: ", this.currentUserIdValue, "; result.updated_by: ", result.updated_by, "; equal: ", this.currentUserIdValue == result.updated_by);
    if(this.currentUserIdValue == result.updated_by) {
      console.log("Updating UI for result updated by current user:", result);
      colour = "green";
      updatedElements.push(regularPointsInput, bonusPointsInput);
    } else {
      if (regularPointsInput.value !== result.regular_points.toString()) {
        regularPointsInput.value = result.regular_points;
        updatedElements.push(regularPointsInput);
      }
  
      if (bonusPointsInput.value !== result.bonus_points.toString()) {
        bonusPointsInput.value = result.bonus_points;
        updatedElements.push(bonusPointsInput);
      }
    }

    if (statusElement.textContent !== result.status) {
      statusElement.textContent = result.status;
      updatedElements.push(statusElement);
    }

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

  handleWebSocketUpdate(data) {
    if (data.user_id == this.userIdValue) {
      console.log("Controller received data for current user:", data);
      this.updateUI(data);
    } else {
      console.log("WARNING: Received data for wrong user:", data, "; data.user_id: ", data.user_id, "; this.userIdValue: ", this.userIdValue);
    }
  }
}