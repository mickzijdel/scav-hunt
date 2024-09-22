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

  def self.teams_ranked
    self.where(role: :team).includes(:results).sort_by { |team| -team.results.sum(&:total_points) }
  end
end
