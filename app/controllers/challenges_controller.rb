require "csv"

class ChallengesController < ApplicationController
  load_and_authorize_resource

  # GET /challenges or /challenges.json
  def index
    @title = "Challenges"
    @challenges = Challenge.by_number

    # Include the results for this user if the user is a team.
    if current_user.team?
      @results = Result.includes(:challenge).where(user: current_user).index_by(&:challenge_id)
    end
  end

  # GET /challenges/1 or /challenges/1.json
  def show
    @title = @challenge.title
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

  def import_form
    @title = "Import Challenges"
  end

  def import
    # FIXME: This logic should live in a helper.
    file = params.dig(:import, :file)
    if file.present?
      begin
        imported_challenges = []
        CSV.foreach(file.path, headers: true) do |row|
          challenge = Challenge.find_or_initialize_by(number: row["Number"])
          challenge.assign_attributes(
            description: row["Description"],
            points: row["Points"],
            group_id: row["GroupID"]
          )
          imported_challenges << challenge if challenge.changed?
        end

        Challenge.import imported_challenges, on_duplicate_key_update: [ :description, :points, :group_id ]
        redirect_to challenges_path, notice: "Challenges imported successfully."
      rescue => e
        # TODO: The alerts don't show up? Probably a turbo thing. Only show on page reload.
        print(e)
        flash[:alert] = "Error importing challenges: #{e.message}"
        render "import_form"
      end
    else
      flash[:alert] = "Please select a file to import."
      render "import_form"
    end
  end

  def export
    @challenges = Challenge.includes(results: :user).order(:number)
    @teams = User.teams_by_name

    response.headers["Content-Type"] = "text/csv"
    response.headers["Content-Disposition"] = "attachment; filename=challenges-#{Date.today}.csv"

    render template: "challenges/export", formats: :csv
  end

  private
  # Only allow a list of trusted parameters through.
  def challenge_params
    params.require(:challenge).permit(:number, :description, :points, :group_id)
  end

  def set_edit_challenge_title
    @title = "Editing Challenge #{@challenge.title}"
  end

  def set_new_challenge_title
    @title = "New Challenge"
  end
end
