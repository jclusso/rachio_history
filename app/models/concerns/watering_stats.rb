# Aggregations over completed watering runs, shared by Controller and Zone.
module WateringStats
  extend ActiveSupport::Concern

  def watering_runs(range = nil)
    scope = events.zone_completed.includes(:zone).recent_first
    scope = scope.between(range.begin, range.end) if range
    scope
  end

  # { Date => minutes } for the heatmap and calendar.
  def daily_watering_minutes(range)
    events.zone_completed.between(range.begin, range.end)
          .group_by { |event| event.occurred_at.to_date }
          .transform_values { |group| group.sum { |event| event.duration_seconds.to_i } / 60 }
  end

  # { Date => [[zone name, minutes], ...] }, most-watered zone first — the
  # per-day detail behind the heatmap tooltip.
  def daily_watering_breakdown(range)
    events.zone_completed.includes(:zone).between(range.begin, range.end)
          .group_by { |event| event.occurred_at.to_date }
          .transform_values do |group|
            group.group_by { |event| event.zone&.name.presence || "Unmatched zone" }
                 .map { |name, runs| [ name, runs.sum { |event| event.duration_seconds.to_i } / 60 ] }
                 .sort_by { |_name, minutes| -minutes }
          end
  end

  def watering_seconds(range = nil)
    watering_runs(range).sum { |event| event.duration_seconds.to_i }
  end

  # [ [zone, minutes], ... ] most-watered first.
  def minutes_by_zone(range = nil)
    watering_runs(range).group_by(&:zone).filter_map do |zone, group|
      next if zone.nil?
      [ zone, group.sum { |event| event.duration_seconds.to_i } / 60 ]
    end.sort_by { |_zone, minutes| -minutes }
  end

  # { Date(first of month) => minutes } for the last 12 months.
  def minutes_by_month
    watering_runs(1.year.ago..Time.current)
      .group_by { |event| event.occurred_at.to_date.beginning_of_month }
      .transform_values { |group| group.sum { |event| event.duration_seconds.to_i } / 60 }
  end
end
