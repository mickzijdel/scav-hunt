class HomeController < ApplicationController
  def index
    @title = "Scoreboard"
    @teams = User.teams_ranked

    # TODO: Cache until the scores change -> On result update.

    respond_to do |format|
      format.html
      format.json { render json: @teams.map { |team| team.scoreboard_data(current_ability) } }
    end
  end
end
