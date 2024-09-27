class ScoringChannel < ApplicationCable::Channel
  def subscribed
    stream_from "scoring_#{params[:user_id]}"
    Rails.logger.info "Subscribed to ScoringChannel for user: #{params[:user_id]}"
  end

  def receive(data)
    Rails.logger.info "Received data in ScoringChannel: #{data}"
    ActionCable.server.broadcast("scoring_#{params[:user_id]}", data)
  end
end
