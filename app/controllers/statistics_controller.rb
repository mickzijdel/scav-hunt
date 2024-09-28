class StatisticsController < ApplicationController
  authorize_resource class: :statistics

  def index
    @title = "Statistics"
    @created_at_data = points_over_time(:created_at)
    @updated_at_data = points_over_time(:updated_at)
  end

  private

  # FIXME: This should not live in the controller. Move it.
  # FIXME: This needs testing.
  def points_over_time(time_column)
    start_time = [ Result.order(time_column).first&.send(time_column) || 0, Setting.get("scoreboard_end_time").advance(days: -1) ].max
    end_time = Result.order(time_column).last&.send(time_column) || Time.current

    time_intervals = generate_time_intervals(start_time, end_time)

    data = [ [ "timestamps" ] + time_intervals ]

    # Generate each team's point series and add it to the data.
    # The data consists of an array of arrays, the inner array representing the series of points for a team.
    # The first item of the array is the team name.
    User.teams_by_name.includes(:results).each do |team|
      team_data = [ team.name ]
      team_data += time_intervals.map do |interval|
        team.results.where("#{time_column} <= ?", interval)
                    .sum("regular_points + bonus_points")
      end
      data << team_data
    end

    data
  end

  def generate_time_intervals(start_time, end_time)
    intervals = []
    current_time = start_time.change(min: (start_time.min / 30) * 30, sec: 0)

    # End time + 30.minutes so that we round up.
    while current_time <= end_time + 30.minutes
      intervals << current_time
      current_time += 30.minutes
    end

    intervals
  end
end
