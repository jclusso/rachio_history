# Single-row table for operator-supplied configuration. The Rachio API key
# lives here rather than in Rails credentials so it never enters the repo.
class Setting < ApplicationRecord
  encrypts :rachio_api_key

  validates :rachio_api_key, presence: true

  # Pinning the singleton to id 1 keeps a concurrent first save from creating a
  # second row. Unsaved until configured, so reading settings never writes.
  def self.current
    find_or_initialize_by(id: 1)
  end

  def rachio_api_key_hint
    "••••#{rachio_api_key.last(4)}" if rachio_api_key.present?
  end
end
