# frozen_string_literal: true

require "net/http"
require "json"

# Fetches v1 compat session / public context when COMPAT_API_READ_ENABLED=true.
module CompatSession
  extend ActiveSupport::Concern
  include CompatReadFlags

  included do
    helper_method :compat_read_enabled? if respond_to?(:helper_method)
  end

  private

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

  def compat_auth_session(owner_id: nil, current_user_id: nil)
    return nil unless compat_read_data_plane?

    owner_id = resolve_compat_owner_id(owner_id)
    current_user_id = resolve_compat_current_user_id(current_user_id)
    return nil unless owner_id

    @compat_auth_sessions ||= {}
    cache_key = [owner_id, current_user_id]
    return @compat_auth_sessions[cache_key] if @compat_auth_sessions.key?(cache_key)

    @compat_auth_sessions[cache_key] = fetch_v1_json(
      "/auth/session",
      {
        business_owner_id: owner_id,
        current_user_id: current_user_id,
      }.compact
    )&.dig("data")
  end

  def resolve_compat_owner_id(owner_id)
    resolve_compat_id(owner_id) || resolve_compat_id(params[:business_owner_id])
  end

  def resolve_compat_current_user_id(current_user_id)
    resolved = resolve_compat_id(current_user_id)
    return resolved if resolved

    if respond_to?(:user_bot_cookies, true)
      cookie_id = user_bot_cookies(:current_user_id)
      return resolve_compat_id(cookie_id) if cookie_id.present?
    end

    if respond_to?(:privileged_session_user, true)
      user = privileged_session_user
      return user.id if user
    end

    nil
  end

  def resolve_compat_id(value)
    return nil if value.blank?

    id = value.to_i
    id.positive? ? id : nil
  end

  def public_booking_subscription_active?(slug)
    return nil unless compat_read_data_plane?

    body = fetch_v1_json("/booking/#{slug}/page_context")
    body&.dig("includes", "subscription_active")
  end

  def public_sale_subscription_active?(slug)
    return nil unless compat_read_data_plane?

    body = fetch_v1_json("/sale_pages/#{slug}/page_context")
    body&.dig("includes", "subscription_active")
  end

  def subscription_active_for_public_sale?(sale_page)
    if compat_read_data_plane?
      active = public_sale_subscription_active?(sale_page.slug)
      return active unless active.nil?
    end

    sale_page.user.subscription.active?
  end

  def subscription_active_for_public_booking?(booking_page)
    if compat_read_data_plane?
      active = public_booking_subscription_active?(booking_page.slug)
      return active unless active.nil?
    end

    booking_page.user.subscription.active?
  end
end
