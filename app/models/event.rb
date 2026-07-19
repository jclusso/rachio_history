class Event < ApplicationRecord
  belongs_to :controller
  belongs_to :zone, optional: true

  validates :rachio_id, presence: true, uniqueness: true
  validates :occurred_at, presence: true

  scope :recent_first, -> { order(occurred_at: :desc) }
  scope :zone_runs, -> { where(event_type: "ZONE_STATUS") }
  scope :zone_completed, -> { zone_runs.where(sub_type: [ "ZONE_COMPLETED", "ZONE_STOPPED" ]) }
  scope :between, ->(from, to) { where(occurred_at: from..to) }

  def zone_run?
    event_type == "ZONE_STATUS"
  end

  # Rachio summaries read like "Back Yard watered for 20 minutes." or
  # "... stopped watering at 10:08 PM (EDT) for 20 seconds."
  def duration_seconds
    if (minutes = summary.to_s[/(\d+)\s+minute/, 1])
      minutes.to_i * 60
    elsif (seconds = summary.to_s[/(\d+)\s+second/, 1])
      seconds.to_i
    end
  end

  def duration_minutes
    duration_seconds&./ 60
  end

  # Completed events carry the end time; back out the start.
  def run_started_at
    occurred_at - duration_seconds.to_i
  end

  # Best display name for the zone: the linked zone, or the (possibly
  # truncated) name Rachio put in the summary for zones since renamed/deleted.
  def zone_label
    zone&.name ||
      summary.to_s[/\A(.+?)(?:\.{2,3})?\s+(?:began|completed|stopped|watered)/, 1] ||
      "Unknown zone"
  end
end
