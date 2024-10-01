class GroupPermissionsController < ApplicationController
  load_and_authorize_resource

  def index
    @title = "Manage Group Permissions"
    @users = User.includes(:group_permissions).teams_by_name
  end

  def update
    @user = User.find(params[:user_id])
    @group_id = params[:group_id]

    begin
      if params["permitted"].to_s == "true"
        GroupPermission.find_or_create_by(user: @user, group_id: @group_id)
      else
        GroupPermission.find_by(user: @user, group_id: @group_id)&.destroy
      end

      broadcast_challenges_update(@user)

      render json: { status: "success", result: @user.can_see_group?(@group_id) }
    rescue => e
      render json: { status: "error", errors: e.message }, status: :unprocessable_entity
    end
  end

  private

  def broadcast_challenges_update(user)
    # TODO: Duplicates with challenges#index
    challenges = Challenge.accessible_by(Ability.new(user)).by_number
    results = Result.includes(:challenge).where(user: user).index_by(&:challenge_id)

    html = ApplicationController.render(
      partial: "challenges/challenge_list",
      locals: { challenges: challenges, results: results, current_user: user }
    )

    GroupUpdatesChannel.broadcast_to(user, { action: "update_challenges", challenges: html })
  end
end
