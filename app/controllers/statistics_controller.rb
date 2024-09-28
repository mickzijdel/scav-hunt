class StatisticsController < ApplicationController
  authorize_resource class: :statistics

  def index
    @title = "Statistics"
    @created_at_data = StatisticsService.points_over_time(:created_at)
    @updated_at_data = StatisticsService.points_over_time(:updated_at)
  end
end
