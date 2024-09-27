import { Controller } from "@hotwired/stimulus"
import consumer from "../channels/consumer"

export default class extends Controller {
  static targets = ["challengeList"]
  static values = { userId: Number }

  connect() {
    if (this.hasUserIdValue && this.userIdValue != 0) {
      console.log("Connecting to GroupUpdatesChannel for user", this.userIdValue)
      this.channel = consumer.subscriptions.create(
        { channel: "GroupUpdatesChannel", user_id: this.userIdValue },
        {
          connected: () => {
            console.log("Connected to GroupUpdatesChannel")
          },
          disconnected: () => {
            console.log("Disconnected from GroupUpdatesChannel")
          },
          received: this.handleUpdate.bind(this)
        }
      )
    }
  }

  disconnect() {
    if (this.channel) {
      this.channel.unsubscribe()
    }
  }

  handleUpdate(data) {
    if (data.action === "update_challenges") {
      this.updateChallengeList(data.challenges)
    }
  }

  updateChallengeList(challenges) {
    this.challengeListTarget.innerHTML = challenges
    this.dispatch("challengesUpdated")
  }
}