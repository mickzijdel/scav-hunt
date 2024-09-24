class Challenge < ApplicationRecord
  validates :number, :description, :points, :group_id, presence: true
  validates :points, :number, numericality: { only_integer: true }
  validates :number, :description, uniqueness: true

  has_many :results
  has_many :users, through: :results

  # TODO: Properly implement deleting challenges that have results attached.

  scope :by_number, -> { order(:number) }

  def title
    "Challenge #{number} - \"#{description}\""
  end

  def self.group_ids
    self.pluck(:group_id).compact.uniq.sort
  end
end
