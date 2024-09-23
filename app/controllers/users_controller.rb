class UsersController < ApplicationController
  load_and_authorize_resource

  def index
    @title = "Users"
    @users = User.accessible_by(current_ability).order(:role, :name)
  end

  def show
    @title = @user.name.presence || "User"
  end

  def new
    set_new_user_title
  end

  def edit
    set_edit_user_title
  end

  def create
    # TODO: Issues with creating a user. Gives error: " You are already signed in. "
    @user = User.new(user_params)

    if @user.save
      redirect_to @user, notice: "User was successfully created."
    else
      set_new_user_title
      render :new, status: :unprocessable_entity
    end
  end

  def update
    params = user_params

    if params[:password].blank? && params[:password_confirmation].blank?
      params.delete(:password)
      params.delete(:password_confirmation)
    end

    if @user.update(params)
      redirect_to @user, notice: "User was successfully updated."
    else
      set_edit_user_title
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @user.destroy
    redirect_to users_url, notice: "User was successfully destroyed."
  end

  private

  def user_params
    params.require(:user).permit(:email, :name, :role, :password, :password_confirmation)
  end

  def set_edit_user_title
    @title = "Edit #{@user.name}"
  end

  def set_new_user_title
    @title = "New User"
  end
end
