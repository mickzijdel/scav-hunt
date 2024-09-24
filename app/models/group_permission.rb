class GroupPermission < ApplicationRecord
  belongs_to :user
  validates :group_id, presence: true, uniqueness: { scope: :user_id }
end
