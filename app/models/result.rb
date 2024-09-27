class Result < ApplicationRecord
  belongs_to :user
  belongs_to :challenge

  # TODO: Add comment field

  validates :regular_points, :bonus_points, presence: true, numericality: { only_integer: true }

  after_save :clear_scoreboard_cache, :broadcast_update
  before_destroy :ensure_zero_points

  attr_accessor :updated_by_id

  # If a result changes, the scoreboard needs updating.
  # FIXME: Could be improved by caching on a per-team basis.
  def clear_scoreboard_cache
    Rails.cache.delete("teams_ranked")
    Rails.cache.delete("teams_json")
  end

  def total_points
    regular_points + bonus_points
  end

  def status
    if total_points == 0
      "Not Attempted"
    elsif regular_points >= challenge.points
      "Completed"
    else
      "Partially Completed"
    end
  end

  def as_json
        {
          id: id,
          user_id: user_id,
          challenge_id: challenge_id,
          regular_points: regular_points,
          bonus_points: bonus_points,
          status: status
        }
  end

  def broadcast_update
    ActionCable.server.broadcast("scoring_#{user_id}", {
      user_id: user_id,
      challenge_id: challenge_id,
      regular_points: regular_points,
      bonus_points: bonus_points,
      status: status,
      total_points: user.reload.total_points,
      updated_by: updated_by_id
    })

    self.updated_by_id = nil
  end

  private

  def ensure_zero_points
    if regular_points != 0 || bonus_points != 0
      errors.add(:base, "Cannot destroy result with non-zero points")
      throw :abort
    end
  end
end
