import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  updateScore(event) {
    const input = event.target
    const challengeId = input.dataset.challengeId
    const userId = input.dataset.userId
    const regularPoints = this.regularPointsTargets.find(target => 
      target.dataset.challengeId === challengeId && target.dataset.userId === userId
    ).value
    const bonusPoints = this.bonusPointsTargets.find(target => 
      target.dataset.challengeId === challengeId && target.dataset.userId === userId
    ).value

    this.sendUpdateRequest(challengeId, userId, regularPoints, bonusPoints)
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
        console.log('Score updated successfully')
      } else {
        console.error('Error updating score:', data.errors)
      }
    })
    .catch(error => console.error('Error:', error))
  }
}