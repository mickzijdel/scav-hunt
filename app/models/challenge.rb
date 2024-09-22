class Challenge < ApplicationRecord
  validates :number, :description, :points, presence: true
  validates :points, :number, numericality: { only_integer: true }
  validates :number, :description, uniqueness: true

  has_many :results
  has_many :users, through: :results

  # TODO: Properly implement deleting challenges that have results attached.

  scope :by_number, -> { order(:number) }

  def title
    "Challenge #{number} - \"#{description}\""
  end
end
