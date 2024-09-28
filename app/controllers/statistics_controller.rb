class StatisticsController < ApplicationController
  authorize_resource class: :statistics
  def index
    @title = "Statistics"

    @challenge_data = Challenge.group(:group_id).count
  end
end
