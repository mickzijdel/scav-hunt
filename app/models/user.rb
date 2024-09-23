class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  validates :email, :name, uniqueness: true
  validates :email, :encrypted_password, :role, :name, presence: true

  has_many :results
  has_many :challenges, through: :results

  enum :role, {
     team: 0,
     scorer: 1,
     admin: 2
  }

  after_save :clear_scoreboard_cache

  # If a result changes, the scoreboard needs updating.
  # FIXME: Could be improved by caching on a per-team basis.
  def clear_scoreboard_cache
    Rails.cache.delete("teams_ranked")
    Rails.cache.delete("teams_json")
  end

  def self.teams_ranked
    self.where(role: :team).includes(:results).sort_by { |team| -team.results.sum(&:total_points) }
  end

  def self.teams_by_name
    self.where(role: :team).order(:name)
  end

  def total_points
    results.sum(&:total_points)
  end

  def stats
    not_attempted = Result.where(user: self).where("regular_points = 0 AND bonus_points = 0").count
    completed = Result.where(user: self).where("regular_points >= challenges.points").joins(:challenge).count

    {
      completed: completed,
      partially_completed: Challenge.count - not_attempted - completed,
      not_attempted: not_attempted
    }
  end

  # TODO: Test this
  def scoreboard_data(ability = nil)
    out = {
      id: id,
      name: name,
      score: results.sum(&:total_points)
    }

    out.merge!(stats) if ability.can?(:manage, :scoring)

    out
  end
end
