import { Controller } from "@hotwired/stimulus"
import { connectToScoringChannel } from "../channels/scoring_channel"

// Duuplicates a lot from scoring_controller, but simpler to just keep them separate.
export default class extends Controller {
  static targets = ["regularPoints", "bonusPoints", "status", "totalPoints"]
  static values = { userId: Number }

  connect() {
    if (this.hasUserIdValue) {
      connectToScoringChannel(this, this.userIdValue);
    }
  }

  handleWebSocketUpdate(data) {
    const challengeId = data.challenge_id;
    const regularPointsElement = this.regularPointsTargets.find(el => el.dataset.challengeId == challengeId);
    const bonusPointsElement = this.bonusPointsTargets.find(el => el.dataset.challengeId == challengeId);
    const statusElement = this.statusTargets.find(el => el.dataset.challengeId == challengeId);

    if (regularPointsElement) regularPointsElement.textContent = data.regular_points;
    if (bonusPointsElement) bonusPointsElement.textContent = data.bonus_points;
    if (statusElement) statusElement.textContent = data.status;

    this.updateTotalPoints(data.total_points);
  }

  updateTotalPoints(totalPoints) {
    if (this.hasTotalPointsTarget) {
      this.totalPointsTarget.textContent = totalPoints;
    }
  }

  // TODO: Listen to updates on the visible group ids and update challenge list accordingly.
}
