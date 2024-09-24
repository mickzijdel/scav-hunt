class HomeController < ApplicationController
  def index
    @title = "Scoreboard"
    @teams = Rails.cache.fetch("teams_ranked", expires_in: 5.minutes) do
      User.teams_ranked
    end

    @end_time = Setting.get("scoreboard_end_time")
    @scoreboard_visible = Setting.get("scoreboard_visible")

    respond_to do |format|
      format.html
      format.json { render json: teams_json }
    end
  end

  private

  def teams_json
    Rails.cache.fetch("teams_json", expires_in: 1.minute) do
      @teams.map { |team| team.scoreboard_data(current_ability) }
    end
  end
end
