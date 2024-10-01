import consumer from "./consumer"

export function connectToScoringChannel(controller, userId, connectionCallback) {
  console.log("ScorringChannel: Connecting for user:", userId, "...");

  try {
    controller.scoringChannel = consumer.subscriptions.create(
      { channel: "ScoringChannel", user_id: userId },
      {
        connected() {
          console.log("ScoringChannel: Connected")
          connectionCallback(true)
        },

        disconnected() {
          console.log("ScoringChannel: Disconnected ")
          connectionCallback(false)
        },

        received(data) {
          console.info("ScoringChannel: Received data:", data);
          controller.handleWebSocketUpdate(data)
        }
      }
    )
  } catch (error) {
    console.error("ScoringChannel: Failed to create subscription", error);
    connectionCallback(false);
  }
}
