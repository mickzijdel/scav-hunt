class GroupUpdatesChannel < ApplicationCable::Channel
  def subscribed
    user = User.find(params[:user_id])
    stream_for user

    Rails.logger.info "Subscribed to GroupUpdatesChannel for user: #{params[:user_id]}"
  end
end
