# Fetches one 28-day window of history per run, then re-enqueues itself for
# the next (older) window. Keeps each job short and plays nice with Rachio's
# daily rate limit (~1700 calls/day).
class BackfillControllerJob < ApplicationJob
  queue_as :backfill
  retry_on Rachio::RateLimited, wait: 1.hour, attempts: 10

  def perform(controller)
    more = controller.backfill_next_window!
    self.class.set(wait: 2.seconds).perform_later(controller) if more
  end
end
