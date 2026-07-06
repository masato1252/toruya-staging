# frozen_string_literal: true

require "net/http"
require "json"

# Fetches v1 compat session / public context when COMPAT_API_READ_ENABLED=true.
module CompatSession
  extend ActiveSupport::Concern

  private

  def compat_read_data_plane?
    ENV["COMPAT_API_READ_ENABLED"] == "true" && ENV["COMPAT_API_ORIGIN"].present?
  end

  def fetch_v1_json(path, query = {})
    origin = ENV["COMPAT_API_ORIGIN"].to_s.sub(%r{/$}, "")
    uri = URI("#{origin}/v1/compat#{path}")
    uri.query = URI.encode_www_form(query) if query.any?

    request = Net::HTTP::Get.new(uri)
    request["Cookie"] = cookies.map { |k, v| "#{k}=#{v}" }.join("; ") if cookies.present?
    request["Accept"] = "application/json"

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https", open_timeout: 5, read_timeout: 10) do |http|
      http.request(request)
    end

    return nil unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body)
  rescue StandardError => e
    Rails.logger.warn("[CompatSession] #{path} failed: #{e.message}")
    nil
  end

  def compat_auth_session(owner_id: business_owner_id, current_user_id: current_user&.id)
    return nil unless compat_read_data_plane?

    @compat_auth_session ||= fetch_v1_json(
      "/auth/session",
      {
        business_owner_id: owner_id,
        current_user_id: current_user_id,
      }.compact
    )&.dig("data")
  end

  def public_booking_subscription_active?(slug)
    return nil unless compat_read_data_plane?

    body = fetch_v1_json("/booking/#{slug}/page_context")
    body&.dig("includes", "subscription_active")
  end
end
