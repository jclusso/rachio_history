# Pulls all devices on the Rachio account and refreshes recent events for each.
class SyncAccountJob < ApplicationJob
  queue_as :default
  retry_on Rachio::RateLimited, wait: 1.hour, attempts: 5

  def perform
    # Merged controllers are retired hardware — their history now lives on the
    # successor, so there is nothing new to pull for them.
    Controller.sync_account!.reject(&:merged?).each do |controller|
      SyncControllerJob.perform_later(controller)
    end
  end
end
