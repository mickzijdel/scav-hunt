class Challenge < ApplicationRecord
  validates :number, :description, :points, :group_id, presence: true
  validates :points, :number, numericality: { only_integer: true }
  # Number is the challenge's identity -- it is what the CSV import matches rows on
  # and what the list is ordered by -- and is backed by a unique index.
  #
  # Description deliberately is NOT unique. It was, unindexed, so every single save
  # paid a full table scan to enforce a rule the database never held; and two
  # challenges legitimately sharing wording is entirely plausible in a hunt that
  # repeats a task across groups. Nothing in the app treats the description as a key.
  validates :number, uniqueness: true
  validates :description, length: { maximum: 255 }

  has_many :results, dependent: :destroy
  has_many :users, through: :results

  scope :by_number, -> { order(:number) }

  # The challenges a user is allowed to see, in the order they are displayed. Used
  # both by challenges#index and by the broadcast that re-renders a team's list when
  # their group permissions change, so the two cannot drift apart.
  def self.visible_to(user)
    accessible_by(Ability.new(user)).by_number
  end

  def title
    "Challenge #{number} - \"#{description}\""
  end

  # Every group that has at least one challenge in it, in order. Was
  # pluck.compact.uniq.sort, which pulled a row per challenge back into Ruby to
  # answer a question the database answers with SELECT DISTINCT ... ORDER BY.
  def self.group_ids
    where.not(group_id: nil).distinct.order(:group_id).pluck(:group_id)
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
