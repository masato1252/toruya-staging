# frozen_string_literal: true

require "net/http"
require "json"

class LineInsightClient
  FOLLOWERS_PATH = "/v2/bot/insight/followers"
  DEMOGRAPHIC_PATH = "/v2/bot/insight/demographic"

  class Error < StandardError; end

  def self.get_number_of_followers(channel_token:, date:)
    get(channel_token:, date:, path: FOLLOWERS_PATH)
  end

  def self.get_demographic(channel_token:, date:)
    get(channel_token:, date:, path: DEMOGRAPHIC_PATH)
  end

  def self.get(channel_token:, date:, path:)
    uri = URI("https://api.line.me#{path}")
    uri.query = URI.encode_www_form(date: date) if date.present?

    request = Net::HTTP::Get.new(uri)
    request["Authorization"] = "Bearer #{channel_token}"

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.open_timeout = 10
      http.read_timeout = 30
      http.request(request)
    end

    body = JSON.parse(response.body)

    unless response.is_a?(Net::HTTPSuccess)
      raise Error, "HTTP #{response.code}: #{body}"
    end

    body
  rescue JSON::ParserError => e
    raise Error, "Invalid JSON: #{e.message}"
  end
end
