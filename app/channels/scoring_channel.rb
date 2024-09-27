class ScoringChannel < ApplicationCable::Channel
  def subscribed
    user = User.find(params[:user_id])
    stream_for user
    Rails.logger.info "Subscribed to ScoringChannel for user: #{params[:user_id]}"
  end

  def receive(data)
    Rails.logger.info "Received data in ScoringChannel: #{data}"
    ActionCable.server.broadcast("scoring_#{params[:user_id]}", data)
  end
end
