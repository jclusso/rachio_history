# Pulls all devices on the Rachio account and refreshes recent events for each.
class SyncAccountJob < ApplicationJob
  queue_as :default
  retry_on Rachio::RateLimited, wait: 1.hour, attempts: 5

  def perform
    Controller.sync_account!.each do |controller|
      SyncControllerJob.perform_later(controller)
    end
  end
end
