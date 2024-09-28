import { Controller } from "@hotwired/stimulus"
import consumer from "../channels/consumer"

export default class extends Controller {
  static targets = ["challengeList"]
  static values = { userId: Number }

  connect() {
    if (this.hasUserIdValue && this.userIdValue != 0) {
      console.log("Group Updates Channel: Connecting for user", this.userIdValue, "...")
      
      try {
        this.channel = consumer.subscriptions.create(
          { channel: "GroupUpdatesChannel", user_id: this.userIdValue },
          {
            connected: () => {
              console.log("GroupUpdatesChannel: Connected")
            },
            disconnected: () => {
              console.log("GroupUpdatesChannel: Disconnected")
            },
            received: this.handleUpdate.bind(this)
          }
        )
      } catch (error) {
        console.error("ERROR - GroupUpdatesChannel: Failed to create subscription", error);
      }
    }
  }

  disconnect() {
    if (this.channel) {
      this.channel.unsubscribe()
    }
  }

  handleUpdate(data) {
    console.info("GroupUpdatesController: Received data:", data)

    if (data.action === "update_challenges") {
      this.updateChallengeList(data.challenges)
    }
  }

  updateChallengeList(challenges) {
    console.info("GroupUpdatesController: Updating challenge list...")

    this.challengeListTarget.innerHTML = challenges
    this.dispatch("challengesUpdated")
  }
}