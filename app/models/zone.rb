class Zone < ApplicationRecord
  include WateringStats

  belongs_to :controller
  has_many :events, dependent: :nullify
  has_many :zone_aliases, dependent: :destroy

  validates :rachio_id, presence: true, uniqueness: true

  scope :ordered, -> { order(:number) }
  scope :enabled, -> { where(enabled: true) }

  def runs
    events.zone_runs.recent_first
  end

  def last_watered_at
    events.zone_runs.maximum(:occurred_at)
  end

  def total_run_minutes
    watering_seconds / 60
  end

  # All names this zone has been known by.
  def known_names
    [ name, *zone_aliases.pluck(:name) ].compact_blank
  end

  # Adopt a former zone name: record it as an alias and link every orphaned
  # event on this controller whose summary references it.
  def claim_label!(label)
    zone_aliases.find_or_create_by!(name: label)
    pattern = "#{ZoneAlias.sanitize_sql_like(label)}%"
    controller.events.where(zone_id: nil)
              .where("summary LIKE ? OR summary LIKE ?", pattern, "Soaking #{pattern}")
              .update_all(zone_id: id)
  end
end
