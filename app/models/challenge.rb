class Challenge < ApplicationRecord
  validates :number, :description, :points, :group_id, presence: true
  validates :points, :number, numericality: { only_integer: true }
  validates :number, :description, uniqueness: true

  has_many :results, dependent: :destroy
  has_many :users, through: :results

  scope :by_number, -> { order(:number) }

  def title
    "Challenge #{number} - \"#{description}\""
  end

  def self.group_ids
    self.pluck(:group_id).compact.uniq.sort
  end

  def completion_stats
    total_teams = User.where(role: :team).count
    completed = results.where("regular_points >= ?", points).count
    partially_completed = results.where("regular_points != 0 OR bonus_points != 0").count - completed

    {
      completed: completed,
      partially_completed: partially_completed,
      not_attempted: total_teams - completed - partially_completed
    }
  end
end
