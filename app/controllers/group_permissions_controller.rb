class GroupPermissionsController < ApplicationController
  load_and_authorize_resource

  def index
    @title = "Manage Group Permissions"
    @users = User.includes(:group_permissions).teams_by_name
    @group_ids = Challenge.distinct.pluck(:group_id).compact.sort
  end

  def update
    @user = User.find(params[:user_id])
    @group_id = params[:group_id]

    begin
      if params[:permitted] == "true"
        GroupPermission.find_or_create_by(user: @user, group_id: @group_id)
      else
        GroupPermission.find_by(user: @user, group_id: @group_id)&.destroy
      end

      render json: { status: "success", result: @user.can_see_group?(@group_id) }
    rescue => e
      render json: { status: "error", errors: e.message }, status: :unprocessable_entity
    end
  end
end
