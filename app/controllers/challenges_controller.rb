class ChallengesController < ApplicationController
  load_and_authorize_resource

  # TODO: Make the views look nicer/standardise with the others.

  # GET /challenges or /challenges.json
  def index
    @challenges = Challenge.all.order(:number)

    # Include the results for this user if the user is a team.
    if current_user.team?
      @results = Result.where(user: current_user).index_by(&:challenge_id)
    end
  end

  # TODO: An overview where scorers and admin can assign the scores to the teams.

  # GET /challenges/1 or /challenges/1.json
  def show
  end

  # GET /challenges/new
  def new
    set_new_challenge_title
    @challenge = Challenge.new
  end

  # GET /challenges/1/edit
  def edit
    set_edit_challenge_title
  end

  # POST /challenges or /challenges.json
  def create
    set_new_challenge_title
    @challenge = Challenge.new(challenge_params)

    respond_to do |format|
      if @challenge.save
        format.html { redirect_to challenge_url(@challenge), notice: "Challenge was successfully created." }
        format.json { render :show, status: :created, location: @challenge }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @challenge.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /challenges/1 or /challenges/1.json
  def update
    set_edit_challenge_title

    respond_to do |format|
      if @challenge.update(challenge_params)
        format.html { redirect_to challenge_url(@challenge), notice: "Challenge was successfully updated." }
        format.json { render :show, status: :ok, location: @challenge }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @challenge.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /challenges/1 or /challenges/1.json
  def destroy
    @challenge.destroy!

    respond_to do |format|
      format.html { redirect_to challenges_url, notice: "Challenge was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
  # Only allow a list of trusted parameters through.
  def challenge_params
    params.require(:challenge).permit(:number, :description, :points)
  end

  def set_edit_challenge_title
    @title = "Editing Challenge #{@challenge.number} - \"#{@challenge.description}\""
  end

  def set_new_challenge_title
    @title = "New Challenge"
  end
end
