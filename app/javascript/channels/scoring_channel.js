import consumer from "./consumer"

export function connectToScoringChannel(controller, userId, connectionCallback) {
  console.log("Connecting to ScoringChannel for user:", userId);

  controller.scoringChannel = consumer.subscriptions.create(
    { channel: "ScoringChannel", user_id: userId },
    {
      connected() {
        console.log("Connected to ScoringChannel")
        connectionCallback(true)
      },

      disconnected() {
        console.log("Disconnected from ScoringChannel")
        connectionCallback(false)
      },

      received(data) {
        console.log("Received data:", data);
        controller.handleWebSocketUpdate(data)
      }
    }
  )
}
