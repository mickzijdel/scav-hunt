class SettingsController < ApplicationController
  load_and_authorize_resource

  # GET /settings
  def index
    @title = "Settings"
    @settings = editable_settings
  end

  # PATCH /settings/update
  def update
    update_params = params.require(:setting).permit(:key, :value)
    setting = Setting.set(update_params[:key], update_params[:value])

    respond_to do |format|
      if setting.errors.empty?
        format.html { redirect_to settings_path, notice: "Setting \"#{Setting::KEYS[update_params[:key]][:title]}\" updated successfully." }
      else
        format.html { render_index_with_errors(setting) }
      end
    end
  end

  private

  # find_or_initialize_by, not find_or_create_by: a Setting is invalid until it has a
  # value, so the implicit create fired an INSERT that could only ever fail -- three
  # doomed round trips on every render, and an unpersisted record back regardless.
  def editable_settings
    Setting::KEYS.keys.map { |key| Setting.find_or_initialize_by(key: key) }
  end

  # Re-render the whole page with the rejected setting in place of its stored self,
  # so the form that was submitted comes back carrying its own errors.
  def render_index_with_errors(setting)
    @title = "Settings"
    @settings = editable_settings.map { |existing| existing.key == setting.key ? setting : existing }

    render :index, status: :unprocessable_entity
  end
end
