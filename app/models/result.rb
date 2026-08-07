class Result < ApplicationRecord
  belongs_to :user
  belongs_to :challenge

  # TODO: Add comment field

  validates :regular_points, :bonus_points, presence: true, numericality: { only_integer: true }
  # Mirrors the unique index on [user_id, challenge_id]. Without it a duplicate
  # surfaced as an unhandled ActiveRecord::RecordNotUnique 500 rather than a
  # validation error -- reachable when two scorers open the same team at once.
  validates :challenge_id, uniqueness: { scope: :user_id }

  # after_commit, not after_save: the cache must not be dropped (nor a refresh sent
  # to every scoreboard) for a write that then rolls back. They run in declaration
  # order, so the cache is already cold by the time viewers re-request the page.
  after_commit :clear_scoreboard_cache, :broadcast_scoreboard_refresh
  after_save :broadcast_update
  before_destroy :ensure_zero_points

  # Set by the controller so the broadcast can tell the scorer who made the change
  # apart from everyone else. Not persisted.
  attr_accessor :updated_by_id

  # If a result changes, the scoreboard needs updating.
  # FIXME: Could be improved by caching on a per-team basis.
  def clear_scoreboard_cache
    Scoreboard.clear_cache
  end

  def total_points
    regular_points + bonus_points
  end

  def status
    if regular_points >= challenge.points
      "Completed"
    elsif regular_points != 0 || bonus_points != 0
      "Partially Completed"
    else
      "Not Attempted"
    end
  end

  def after_update_data
    data = {
      id: id,
      user_id: user_id,
      challenge_id: challenge_id,
      regular_points: regular_points,
      bonus_points: bonus_points,
      status: status,
      total_points: user.reload.total_points,
      updated_by: updated_by_id
    }

    self.updated_by_id = nil

    data
  end

  def broadcast_update
    ScoringChannel.broadcast_to(user, after_update_data)
  end

  private

  # Every scoreboard viewer re-requests the page for themselves. That keeps the rank
  # order, the scorer-only stat columns and the scoreboard_visible gate correct per
  # session, which one broadcast of pre-rendered HTML could never be.
  def broadcast_scoreboard_refresh
    Turbo::StreamsChannel.broadcast_refresh_to(Scoreboard::STREAM)
  end

  def ensure_zero_points
    if regular_points != 0 || bonus_points != 0
      errors.add(:base, "Cannot destroy result with non-zero points")
      throw :abort
    end
  end
end
