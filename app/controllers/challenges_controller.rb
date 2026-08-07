require "csv"

class ChallengesController < ApplicationController
  load_and_authorize_resource

  # GET /challenges or /challenges.json
  def index
    @title = "Challenges"
    @challenges = Challenge.visible_to(current_user).includes(:results)

    # Include the results for this user if the user is a team.
    @results = current_user.results_by_challenge if current_user.team?
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
    if @challenge.destroy
      respond_to do |format|
        format.html { redirect_to challenges_url, notice: "Challenge was successfully destroyed." }
        format.json { head :no_content }
      end
    else
      respond_to do |format|
        format.html { redirect_back_or_to challenges_url, alert: [ @challenge, *@challenge.results.to_a ].compact.map { |result| result.errors.full_messages.join(", ") }.join("; ") }
        format.json { render json: @challenge.errors, status: :unprocessable_entity }
      end
    end
  end

  def import_form
    @title = "Import Challenges"
  end

  REQUIRED_IMPORT_HEADERS = %w[Number Description Points GroupID].freeze

  def import
    file = params.dig(:import, :file)
    return import_failed("Please select a file to import.") if file.blank?

    rows = CSV.read(file.path, headers: true)

    # A misspelled header used to make every row["GroupID"] nil, so
    # find_or_initialize_by(number: nil) returned the same record over and over
    # and nothing imported -- while still reporting success.
    missing_headers = REQUIRED_IMPORT_HEADERS - (rows.headers || [])
    if missing_headers.any?
      return import_failed("CSV is missing required columns: #{missing_headers.to_sentence}.")
    end

    challenges = rows.filter_map do |row|
      challenge = Challenge.find_or_initialize_by(number: row["Number"])
      challenge.assign_attributes(
        description: row["Description"],
        points: row["Points"],
        group_id: row["GroupID"]
      )
      challenge if challenge.changed?
    end

    result = Challenge.import(challenges, on_duplicate_key_update: [ :description, :points, :group_id ])

    # activerecord-import validates by default and simply skips whatever fails,
    # collecting it in failed_instances. Discarding that return value meant a
    # half-imported challenge list reported success.
    if result.failed_instances.any?
      import_failed(import_rejection_message(result.failed_instances, challenges.size))
    else
      redirect_to challenges_path, notice: "Imported #{challenges.size} #{'challenge'.pluralize(challenges.size)}."
    end
  rescue CSV::MalformedCSVError => e
    import_failed("Could not read that file as CSV: #{e.message}")
  end

  def export
    @challenges = Challenge.includes(results: :user).order(:number)
    @teams = User.teams_by_name

    response.headers["Content-Type"] = "text/csv"
    response.headers["Content-Disposition"] = "attachment; filename=challenges-#{Date.today}.csv"

    render template: "challenges/export", formats: :csv
  end

  private

  # Turbo discards a 200 response to a form submission, which is why the old
  # code's flash "didn't show up" -- it needed an error status, and flash.now
  # rather than flash, which targets the *next* request.
  def import_failed(message)
    @title = "Import Challenges"
    flash.now[:alert] = message
    render "import_form", status: :unprocessable_entity
  end

  def import_rejection_message(failed, attempted)
    details = failed.first(5).map do |challenge|
      "##{challenge.number}: #{challenge.errors.full_messages.to_sentence}"
    end
    details << "and #{failed.size - 5} more" if failed.size > 5

    "Imported #{attempted - failed.size} of #{attempted}; " \
      "#{failed.size} rejected -- #{details.join('; ')}"
  end

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
