class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  validates :email, :name, uniqueness: true
  validates :email, :encrypted_password, :role, :name, presence: true

  # results and group_permissions both hold a foreign key to users, so without
  # a dependent: option destroying a user raises ActiveRecord::InvalidForeignKey
  # rather than failing cleanly. Results are destroyed one at a time so that
  # Result#ensure_zero_points still gets to veto deleting a scored team.
  has_many :results, dependent: :destroy
  has_many :challenges, through: :results
  has_many :group_permissions, dependent: :delete_all

  enum :role, {
     team: 0,
     scorer: 1,
     admin: 2
  }

  after_save :clear_scoreboard_cache

  # If a result changes, the scoreboard needs updating.
  # FIXME: Could be improved by caching on a per-team basis.
  def clear_scoreboard_cache
    Scoreboard.clear_cache
  end

  def self.teams_ranked
    self.where(role: :team)
        .left_joins(:results)
        .group("users.id")
        .select("users.*, COALESCE(SUM(results.regular_points + results.bonus_points), 0) as total_points")
        .order("total_points DESC, users.name ASC")
  end

  def self.teams_by_name
    self.where(role: :team).order(:name)
  end

  def total_points
    results.sum(&:total_points)
  end

  def stats
    completed = Result.where(user: self).where("regular_points >= challenges.points AND regular_points != 0").joins(:challenge).count
    partially_completed = Result.where(user: self).where("regular_points != 0 OR bonus_points != 0").count - completed

    {
      completed: completed,
      partially_completed: partially_completed,
      not_attempted: Challenge.count - completed - partially_completed
    }
  end

  def visible_groups
    group_permissions.pluck(:group_id)
  end

  def can_see_group?(group_id)
    visible_groups.include?(group_id)
  end
end
