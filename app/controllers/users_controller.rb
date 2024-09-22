class UsersController < ApplicationController
  load_and_authorize_resource

  def index
    @title = "Users"
    @users = User.accessible_by(current_ability).order(:role, :name)
  end

  def show
    @title = @user.name
  end

  def new
  end

  def edit
  end

  def create
    # TODO: Password checks?

    if @user.save(user_params)
      redirect_to @user, notice: "User was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @user.update(user_params)
      redirect_to @user, notice: "User was successfully updated."
    else
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
end