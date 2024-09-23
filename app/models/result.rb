class Result < ApplicationRecord
  belongs_to :user
  belongs_to :challenge

  # TODO: Add comment field

  validates :regular_points, :bonus_points, presence: true, numericality: { only_integer: true }

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
