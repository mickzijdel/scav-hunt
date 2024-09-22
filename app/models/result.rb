class Result < ApplicationRecord
  belongs_to :user
  belongs_to :challenge

  # TODO: Add comment field

  validates :regular_points, :bonus_points, presence: true, numericality: { only_integer: true }

  def total_points
    regular_points + bonus_points
  end
end
