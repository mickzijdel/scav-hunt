class Result < ApplicationRecord
  belongs_to :user
  belongs_to :challenge

  # TODO: Add comment field

  validates :regular_points, :bonus_points, presence: true, numericality: { only_integer: true }

  after_save :clear_scoreboard_cache

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
end
