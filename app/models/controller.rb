class Controller < ApplicationRecord
  include RachioSyncable
  include EventIngestible
  include Backfillable
  include Mergeable
  include WateringStats

  has_many :zones, dependent: :destroy
  has_many :events, dependent: :destroy

  validates :rachio_id, presence: true, uniqueness: true

  broadcasts_refreshes

  # Pulls anything new since the last event we have (with a little overlap).
  #
  # Rachio won't answer a window wider than EVENT_WINDOW, so a gap longer than
  # that — the app was down for a month, a sync kept failing — has to be walked
  # forward a window at a time. Asking for the whole gap in one request comes
  # back empty, which looks exactly like "nothing new" and leaves the catch-up
  # permanently stuck. Nothing older than the retention window can come back
  # either, so start there at the earliest rather than replaying dead years.
  def sync_recent_events!
    now = Time.current
    cursor = events.maximum(:occurred_at)&.-(1.hour) || Rachio::EVENT_WINDOW.ago
    cursor = [ cursor, Rachio::HISTORY_RETENTION.ago ].max

    while cursor < now
      window_end = [ cursor + Rachio::EVENT_WINDOW, now ].min
      ingest_events(Rachio.device_events(rachio_id, cursor, window_end))
      cursor = window_end
    end

    touch(:last_synced_at)
  end
end
