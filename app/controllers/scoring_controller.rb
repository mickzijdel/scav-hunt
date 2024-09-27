class ScoringController < ApplicationController
  authorize_resource class: :scoring

  def index
    redirect_to root_path
  end

  def score
    @team = User.find(params[:id])

    if !@team.team?
      redirect_to scoring_path, notice: "Only teams can be scored."
    end

    @title = "Scoring #{@team.name}"

    @challenges = Challenge.by_number
    @results = Result.includes(:challenge).where(user: @team).index_by(&:challenge_id)
  end

  def update
    @result = Result.find_or_initialize_by(challenge_id: params[:challenge_id], user_id: params[:user_id])
    @result.regular_points = params[:regular_points]
    @result.bonus_points = params[:bonus_points]
    @result.updated_by_id = current_user.id

    if @result.save
      render json: { status: "success", result: @result.as_json }
    else
      render json: { status: "error", errors: @result.errors.full_messages }, status: :unprocessable_entity
    end
  end
end
