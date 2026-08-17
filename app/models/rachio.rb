# Thin wrapper around the Rachio public API (https://rachio.readme.io).
# The API key is configured in the app and stored encrypted in the database,
# not in Rails credentials — see Setting.
module Rachio
  BASE_URL = "https://api.rach.io/1/public".freeze

  # Rachio limits event queries to windows of ~4 weeks.
  EVENT_WINDOW = 28.days

  # Rachio only serves a rolling window of event history — measured at almost
  # exactly 12 months on every controller we sync, regardless of how long the
  # device has been activated. Anything older comes back empty, so backfills
  # stop here instead of grinding through years of empty EVENT_WINDOW queries
  # against the ~1700 calls/day rate limit. One month of slack over what we
  # observed, in case the real cutoff drifts.
  HISTORY_RETENTION = 13.months

  class Error < StandardError; end
  class RateLimited < Error; end
  class NotFound < Error; end

  class << self
    def api_key
      Setting.current.rachio_api_key.presence ||
        raise(Error, "Rachio API key missing — add it under Settings")
    end

    def person_id
      get("person/info").fetch("id")
    end

    def person
      get("person/#{person_id}")
    end

    def device(device_id)
      get("device/#{device_id}")
    end

    # start_time / end_time are Time-like; Rachio wants epoch milliseconds.
    def device_events(device_id, start_time, end_time)
      get("device/#{device_id}/event?startTime=#{(start_time.to_f * 1000).to_i}&endTime=#{(end_time.to_f * 1000).to_i}")
    end

    def get(path)
      response = HTTPX.with(headers: { "Authorization" => "Bearer #{api_key}" })
                      .get("#{BASE_URL}/#{path}")

      raise Error, "Rachio: #{response.error.message} (#{path})" if response.is_a?(HTTPX::ErrorResponse)

      case response.status
      when 200..299 then response.body.to_s.present? ? response.json : nil
      when 404 then raise NotFound, "Rachio: not found (#{path})"
      when 429 then raise RateLimited, "Rachio: rate limited (resets #{response.headers['x-ratelimit-reset']})"
      else raise Error, "Rachio: #{response.status} (#{path})"
      end
    end
  end
end
