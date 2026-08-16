# Walking a controller's full event history backwards in Rachio-sized windows.
module Backfillable
  extend ActiveSupport::Concern

  def start_backfill!
    update!(backfill_started_at: Time.current, backfill_completed_at: nil, backfill_cursor_at: nil)
    BackfillControllerJob.perform_later(self)
  end

  # Fetches the next (older) window of events. Returns true when there is
  # more history to fetch, false when the backfill is done.
  def backfill_next_window!
    window_end = backfill_cursor_at || Time.current

    # A backfill started before the retention floor existed can have a cursor
    # already older than it. Finish rather than query a backwards window.
    if window_end <= backfill_floor
      update!(backfill_completed_at: Time.current)
      return false
    end

    window_start = [ window_end - Rachio::EVENT_WINDOW, backfill_floor ].max

    ingest_events(Rachio.device_events(rachio_id, window_start, window_end))

    if window_start <= backfill_floor
      update!(backfill_cursor_at: window_start, backfill_completed_at: Time.current)
      false
    else
      update!(backfill_cursor_at: window_start)
      true
    end
  end

  def backfilling?
    backfill_started_at? && !backfill_completed_at?
  end

  def backfill_progress
    return 0 unless backfill_started_at?
    return 100 if backfill_completed_at?

    total = backfill_started_at - backfill_floor
    done = backfill_started_at - (backfill_cursor_at || backfill_started_at)
    return 100 if total <= 0

    (done / total * 100).clamp(0, 99).round
  end

  private

  # How far back history can exist for this controller: never before the
  # device was activated, and never past the end of Rachio's retention window
  # (a 2017 controller still only has the last year of events to give).
  def backfill_floor
    [ rachio_created_at, Rachio::HISTORY_RETENTION.ago ].compact.max
  end
end
