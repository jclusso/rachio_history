# Thin wrapper around the Rachio public API (https://rachio.readme.io).
# Reads the API key from Rails credentials: `rachio: { api_key: ... }`
# or a top-level `rachio_api_key`.
module Rachio
  BASE_URL = "https://api.rach.io/1/public".freeze

  # Rachio limits event queries to windows of ~4 weeks.
  EVENT_WINDOW = 28.days

  class Error < StandardError; end
  class RateLimited < Error; end
  class NotFound < Error; end

  class << self
    def api_key
      Rails.application.credentials.dig(:rachio, :api_key) ||
        raise(Error, "Rachio API key missing from Rails credentials")
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
