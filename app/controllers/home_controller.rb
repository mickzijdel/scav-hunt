class HomeController < ApplicationController
  def index
    @teams = User.where(role: :team).includes(:results).sort_by { |team| -team.results.sum(&:total_points) }

    respond_to do |format|
      format.html
      format.json { render json: @teams.map { |team| { id: team.id, username: team.username, score: team.results.sum(&:total_points) } } }
    end
  end
end
