class Zone < ApplicationRecord
  include WateringStats

  belongs_to :controller
  has_many :events, dependent: :nullify

  validates :rachio_id, presence: true, uniqueness: true

  scope :ordered, -> { order(:number) }

  def runs
    events.zone_runs.recent_first
  end

  def last_watered_at
    events.zone_runs.maximum(:occurred_at)
  end

  def total_run_minutes
    watering_seconds / 60
  end
end
