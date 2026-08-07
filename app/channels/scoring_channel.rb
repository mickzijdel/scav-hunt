class ScoringChannel < ApplicationCable::Channel
  def subscribed
    # params[:user_id] is chosen by the client. Without this check any signed-in
    # team could subscribe to a rival's stream and watch their live scores --
    # including while the scoreboard is deliberately hidden. #receive was already
    # authorized; only reads were missed.
    user = User.find_by(id: params[:user_id])
    return reject if user.nil?
    return reject unless user == current_user || Ability.new(current_user).can?(:manage, :scoring)

    stream_for user
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
