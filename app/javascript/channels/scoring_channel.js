import consumer from "./consumer"

export function connectToScoringChannel(controller, userId) {
  console.log("Connecting to ScoringChannel for user:", userId);

  consumer.subscriptions.create({ channel: "ScoringChannel", user_id: userId }, {
    connected() {
      console.log("Connected to ScoringChannel");
    },

    disconnected() {
      console.log("Disconnected from ScoringChannel");
    },

    received(data) {
      console.log("Received data:", data);
      controller.handleWebSocketUpdate(data);
    }
  });
}
