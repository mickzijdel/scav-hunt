class SettingsController < ApplicationController
  load_and_authorize_resource

  def index
    @title = "Settings"

    @settings = Setting::KEYS.map { |key, details| Setting.find_or_create_by(key: key) }
  end

  def update
    update_params = params.require(:setting).permit(:key, :value)

    Setting.set(update_params[:key], update_params[:value])

    respond_to do |format|
      format.html { redirect_to settings_path, notice: "Setting \"#{Setting::KEYS[update_params[:key]][:title]}\" updated successfully." }
    end
  end
end
