// Opinionated setup from here: https://dev.to/lucaskuhn/a-simple-guide-to-action-cable-2dk2, rather than the default of having one controller per channel.
import * as ActionCable from '@rails/actioncable'
import "./scoring_channel"

window.App || (window.App = {});
window.App.cable = ActionCable.createConsumer();
