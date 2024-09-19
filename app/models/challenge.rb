class Challenge < ApplicationRecord
  validates :number, :description, :points, presence: true
  validates :points, :number, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :number, :description, uniqueness: true
end
