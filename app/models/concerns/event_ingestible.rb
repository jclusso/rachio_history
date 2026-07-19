# Ingesting raw Rachio event payloads into the events table.
module EventIngestible
  extend ActiveSupport::Concern

  # Idempotent: events are keyed by Rachio's event id. Returns count of new events.
  def ingest_events(payloads)
    zones_by_name = zones.index_by(&:name)
    created = 0

    Array(payloads).each do |payload|
      event = events.find_or_initialize_by(rachio_id: payload["id"].to_s)
      next unless event.new_record?

      event.assign_attributes(
        category: payload["category"],
        event_type: payload["type"],
        sub_type: payload["subType"],
        summary: payload["summary"],
        occurred_at: Time.zone.at(payload["eventDate"].to_i / 1000),
        raw: payload,
        zone: match_zone(payload, zones_by_name)
      )
      begin
        event.save!
        created += 1
      rescue ActiveRecord::RecordNotUnique
        # A concurrent sync already inserted this event — safe to skip.
      rescue ActiveRecord::RecordInvalid
        raise unless event.errors.of_kind?(:rachio_id, :taken)
      end
    end

    created
  end

  private

  # Zone events don't carry a zone id; match on the zone name Rachio puts
  # in the summary text (e.g. "Back Yard began watering at ..."). Long zone
  # names get truncated with "..." in summaries, so also match by prefix.
  def match_zone(payload, zones_by_name)
    text = payload["summary"].to_s
    return nil if text.blank?

    exact = zones_by_name.detect { |name, _zone| text.start_with?(name) }&.last
    return exact if exact

    truncated = text[/\A(.+?)\.{2,3}/, 1]
    return nil if truncated.blank?

    zones_by_name.detect { |name, _zone| name.start_with?(truncated) }&.last
  end
end
