class ScoringController < ApplicationController
  authorize_resource class: :scoring

  def index
    # TODO: Add extra features to the scorer side of the scoreboard, such as how many tasks each team has completed etc.
    @title = "Scoreboard"
    @teams = User.teams_ranked

    respond_to do |format|
      format.html { render "home/index" }
    end
  end

  def score
    @team = User.find(params[:id])

    # TODO: Test this case.
    if !@team.team?
      redirect_to scoring_path, notice: "Only teams can be scored."
    end

    @title = "Scoring #{@team.name}"

    @challenges = Challenge.by_number
    @results = Result.where(user: @team).index_by(&:challenge_id)
  end

  def update
    @result = Result.find_or_initialize_by(challenge_id: params[:challenge_id], user_id: params[:user_id])
    @result.regular_points = params[:regular_points]
    @result.bonus_points = params[:bonus_points]

    if @result.save
      render json: { status: "success", result: @result }
    else
      render json: { status: "error", errors: @result.errors.full_messages }, status: :unprocessable_entity
    end
  end
end
