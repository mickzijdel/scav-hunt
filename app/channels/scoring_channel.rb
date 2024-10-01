class ScoringChannel < ApplicationCable::Channel
  def subscribed
    user = User.find(params[:user_id])
    stream_for user
    Rails.logger.info "Subscribed to ScoringChannel for user: #{params[:user_id]}"
  end

  def receive(data)
    return unless Ability.new(current_user).can?(:update, Result)

    challenge_id = data["challenge_id"]
    user_id = data["user_id"]

    result = Result.find_or_initialize_by(challenge_id: challenge_id, user_id: user_id)
    result.regular_points = data["regular_points"]
    result.bonus_points = data["bonus_points"]
    result.updated_by_id = current_user.id

    if result.save
      Rails.logger.info "Updated score for user #{user_id}, challenge #{challenge_id}"
    else
      Rails.logger.error "Failed to update score: #{result.errors.full_messages.join(', ')}"
    end
  end
end
