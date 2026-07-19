# Syncing a controller's details and zones from the Rachio API.
module RachioSyncable
  extend ActiveSupport::Concern

  class_methods do
    # Pulls every device on the account and upserts controllers + zones.
    def sync_account!
      Rachio.person.fetch("devices", []).map do |payload|
        controller = find_or_initialize_by(rachio_id: payload["id"])
        controller.apply_rachio_payload(payload)
        controller.save!
        controller
      end
    end
  end

  def sync_from_rachio!
    apply_rachio_payload(Rachio.device(rachio_id))
    save!
  end

  def apply_rachio_payload(payload)
    self.name = payload["name"]
    self.model = payload["model"]
    self.serial_number = payload["serialNumber"]
    self.mac_address = payload["macAddress"]
    self.status = payload["status"]
    self.timezone = payload["timeZone"]
    self.latitude = payload["latitude"]
    self.longitude = payload["longitude"]
    self.rachio_created_at = Time.zone.at(payload["createDate"].to_i / 1000) if payload["createDate"].present?
    self.last_synced_at = Time.current
    sync_zones(payload["zones"] || [])
  end

  def sync_zones(zone_payloads)
    zone_payloads.each do |payload|
      zone = zones.find_or_initialize_by(rachio_id: payload["id"])
      zone.assign_attributes(
        name: payload["name"],
        number: payload["zoneNumber"],
        enabled: payload["enabled"],
        image_url: payload["imageUrl"]
      )
      zone.save!
    end
  end
end
