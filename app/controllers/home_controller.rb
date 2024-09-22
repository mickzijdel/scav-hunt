class HomeController < ApplicationController
  def index
    @title = "Scoreboard"
    @teams = User.teams_ranked

    respond_to do |format|
      format.html
      format.json { render json: @teams.map { |team| { id: team.id, name: team.name, score: team.results.sum(&:total_points) } } }
    end
  end
end
