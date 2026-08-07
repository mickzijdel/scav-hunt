class StatisticsService
  INTERVAL_MINUTES = 15

  def self.points_over_time(time_column)
    new.points_over_time(time_column)
  end

  def points_over_time(time_column)
    start_time, end_time = chart_window(time_column)

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

  private

  # Both settings are admin-configurable and may simply not exist yet, so neither
  # can be dereferenced blindly. Falling back to the data itself keeps the chart
  # working on a fresh install where nobody has filled the settings in.
  def chart_window(time_column)
    start_time = Setting.get("chart_start_time") || Result.minimum(time_column) || Time.current
    # End time is at most 6 hours after the end of the scav hunt.
    hunt_end = Setting.get("scoreboard_end_time")&.advance(hours: 6)
    end_time = [ Result.maximum(time_column) || Time.current, hunt_end ].compact.min

    # A window that runs backwards would produce an empty time axis.
    [ start_time, [ start_time, end_time ].max ]
  end

  def generate_time_intervals(start_time, end_time)
    intervals = []
    current_time = start_time.change(min: (start_time.min / INTERVAL_MINUTES) * INTERVAL_MINUTES, sec: 0)

    while current_time < end_time
      intervals << current_time
      current_time += INTERVAL_MINUTES.minutes
    end

    # Always finish exactly on end_time rather than a bucket beyond it.
    intervals << end_time
  end
end
