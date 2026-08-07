class GroupPermissionsController < ApplicationController
  load_and_authorize_resource

  # GET /group_permissions
  def index
    @title = "Manage Group Permissions"
    @users = User.includes(:group_permissions).teams_by_name
  end

  # POST /group_permissions
  def update
    @user = User.find(params[:user_id])
    @group_id = params[:group_id].to_i

    if params[:permitted].to_s == "true"
      GroupPermission.find_or_create_by!(user: @user, group_id: @group_id)
    else
      GroupPermission.find_by(user: @user, group_id: @group_id)&.destroy!
    end

    render :update, formats: :turbo_stream
  rescue ActiveRecord::ActiveRecordError => e
    # Re-rendering the checkbox is the rollback: it comes back in whatever state the
    # database is actually in, rather than the state the click assumed.
    flash.now[:alert] = e.message
    render :update, formats: :turbo_stream, status: :unprocessable_entity
  end
end
