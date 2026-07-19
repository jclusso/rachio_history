class Controller < ApplicationRecord
  include RachioSyncable
  include EventIngestible
  include Backfillable
  include WateringStats

  has_many :zones, dependent: :destroy
  has_many :events, dependent: :destroy

  validates :rachio_id, presence: true, uniqueness: true

  broadcasts_refreshes

  # Pulls anything new since the last event we have (with a little overlap).
  def sync_recent_events!
    window_start = events.maximum(:occurred_at)&.-(1.hour) || Rachio::EVENT_WINDOW.ago
    ingest_events(Rachio.device_events(rachio_id, window_start, Time.current))
    touch(:last_synced_at)
  end
end
