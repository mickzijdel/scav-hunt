class GroupPermission < ApplicationRecord
  belongs_to :user

  validates :group_id, presence: true, uniqueness: { scope: :user_id }

  # Granting or revoking a group changes which challenges the team is allowed to see,
  # so their open challenge list is re-rendered for them. This replaces
  # GroupPermissionsController#broadcast_challenges_update, which was
  # Turbo::StreamsChannel.broadcast_update_to written out by hand -- down to a TODO
  # about duplicating challenges#index that Challenge.visible_to now settles.
  after_commit :broadcast_challenge_list

  private

  def broadcast_challenge_list
    Turbo::StreamsChannel.broadcast_update_to [ user, :challenges ],
      target: "challenge_list",
      partial: "challenges/challenge_list",
      locals: { challenges: Challenge.visible_to(user), results: user.results_by_challenge, current_user: user }
  end
end
