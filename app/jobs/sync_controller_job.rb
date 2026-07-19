class SyncControllerJob < ApplicationJob
  queue_as :default
  retry_on Rachio::RateLimited, wait: 1.hour, attempts: 5

  def perform(controller)
    controller.sync_recent_events!
  end
end
