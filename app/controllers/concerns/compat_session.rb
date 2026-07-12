# frozen_string_literal: true

require "net/http"
require "json"
require "openssl"
require "securerandom"

# Fetches v1 compat session / public context when COMPAT_API_READ_ENABLED=true.
module CompatSession
  extend ActiveSupport::Concern
  include CompatReadFlags

  included do
    helper_method :compat_read_enabled? if respond_to?(:helper_method)
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

  def compat_fetch_v1_json(path, query = {})
    fetch_v1_json(path, query)
  end

  def compat_v1_put(path, body = {})
    compat_v1_json_request(Net::HTTP::Put, path, body)
  end

  # Public payment flows need the JSON body on 422 to continue a Stripe 3DS
  # SetupIntent. The legacy callers that only need successful responses should
  # keep using compat_v1_put/post/patch/delete.
  def compat_v1_put_response(path, body = {})
    compat_v1_json_response(Net::HTTP::Put, path, body)
  end

  def compat_v1_post_response(path, body = {})
    compat_v1_json_response(Net::HTTP::Post, path, body)
  end

  def compat_v1_post(path, body = {})
    compat_v1_json_request(Net::HTTP::Post, path, body)
  end

  # Admin file uploads remain same-origin: Rails validates the authenticated
  # session, signs the server-to-server request, and forwards multipart bytes.
  # The browser never receives a v1 credential or proxy secret.
  def compat_v1_multipart_response(request_class, path, body = {}, files = {})
    origin = ENV["COMPAT_API_ORIGIN"].to_s.sub(%r{/$}, "")
    uri = URI("#{origin}/v1/compat#{path}")
    boundary = "----ToruyaCompat#{SecureRandom.hex(16)}"
    request = request_class.new(uri)
    request["Content-Type"] = "multipart/form-data; boundary=#{boundary}"
    request["Cookie"] = cookies.map { |k, v| "#{k}=#{v}" }.join("; ") if cookies.present?
    request["Accept"] = "application/json"
    request["X-CSRF-Token"] = form_authenticity_token if respond_to?(:form_authenticity_token, true)
    apply_compat_admin_proxy_headers(request, uri, request_class.name.demodulize.delete_prefix("Net::HTTP").upcase) if compat_admin_proxy_path?(path)
    request.body = compat_multipart_body(boundary, body, files)

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https", open_timeout: 5, read_timeout: 30) do |http|
      http.request(request)
    end

    {
      success: response.is_a?(Net::HTTPSuccess),
      status: response.code.to_i,
      body: JSON.parse(response.body.presence || "{}")
    }
  rescue StandardError => e
    Rails.logger.warn("[CompatSession] multipart #{request_class.name.demodulize.upcase} #{path} failed: #{e.message}")
    nil
  end

  def compat_v1_patch(path, body = {})
    compat_v1_json_request(Net::HTTP::Patch, path, body)
  end

  def compat_v1_delete(path, body = {})
    compat_v1_json_request(Net::HTTP::Delete, path, body)
  end

  private

  def compat_v1_json_request(request_class, path, body = {})
    response = compat_v1_json_response(request_class, path, body)
    return nil unless response&.dig(:success)

    response[:body]
  end

  def compat_v1_json_response(request_class, path, body = {})
    origin = ENV["COMPAT_API_ORIGIN"].to_s.sub(%r{/$}, "")
    uri = URI("#{origin}/v1/compat#{path}")

    request = request_class.new(uri)
    request["Content-Type"] = "application/json"
    request["Cookie"] = cookies.map { |k, v| "#{k}=#{v}" }.join("; ") if cookies.present?
    request["Accept"] = "application/json"
    request["X-CSRF-Token"] = form_authenticity_token if respond_to?(:form_authenticity_token, true)
    apply_compat_admin_proxy_headers(request, uri, request_class.name.demodulize.delete_prefix("Net::HTTP").upcase) if compat_admin_proxy_path?(path)
    request.body = body.to_json if body.present?

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https", open_timeout: 5, read_timeout: 10) do |http|
      http.request(request)
    end

    {
      success: response.is_a?(Net::HTTPSuccess),
      status: response.code.to_i,
      body: JSON.parse(response.body.presence || "{}")
    }
  rescue StandardError => e
    Rails.logger.warn("[CompatSession] #{request_class.name.demodulize.upcase} #{path} failed: #{e.message}")
    nil
  end

  def compat_multipart_body(boundary, body, files)
    chunks = []
    body.each do |key, value|
      next if value.nil?

      chunks << "--#{boundary}\r\n"
      chunks << "Content-Disposition: form-data; name=\"#{key}\"\r\n\r\n"
      chunks << value.to_s
      chunks << "\r\n"
    end
    files.each do |key, upload|
      next unless upload.respond_to?(:tempfile) && upload.tempfile

      filename = upload.original_filename.to_s.gsub(/["\r\n]/, "_")
      content_type = upload.content_type.presence || "application/octet-stream"
      chunks << "--#{boundary}\r\n"
      chunks << "Content-Disposition: form-data; name=\"#{key}\"; filename=\"#{filename}\"\r\n"
      chunks << "Content-Type: #{content_type}\r\n\r\n"
      chunks << upload.tempfile.binread
      chunks << "\r\n"
    end
    chunks << "--#{boundary}--\r\n"
    chunks.join.b
  end

  def fetch_v1_json(path, query = {})
    origin = ENV["COMPAT_API_ORIGIN"].to_s.sub(%r{/$}, "")
    uri = URI("#{origin}/v1/compat#{path}")
    uri.query = URI.encode_www_form(query) if query.any?

    request = Net::HTTP::Get.new(uri)
    request["Cookie"] = cookies.map { |k, v| "#{k}=#{v}" }.join("; ") if cookies.present?
    request["Accept"] = "application/json"
    apply_compat_admin_proxy_headers(request, uri, "GET") if compat_admin_proxy_path?(path)

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https", open_timeout: 5, read_timeout: 10) do |http|
      http.request(request)
    end

    return nil unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body)
  rescue StandardError => e
    Rails.logger.warn("[CompatSession] #{path} failed: #{e.message}")
    nil
  end

  def resolve_compat_owner_id(owner_id)
    # Must NOT call current_user / business_owner — those call compat_read_data_plane?
    # which calls current_data_plane_owner_id → resolve_compat_owner_id (infinite recursion).
    resolve_compat_id(owner_id) ||
      resolve_compat_id(params[:business_owner_id]) ||
      (respond_to?(:user_bot_cookies, true) ? resolve_compat_id(user_bot_cookies(:current_user_id)) : nil)
  end

  # These are the only V1 endpoints that may rely on Rails' Devise admin
  # session. Owner session and impersonation traffic remain Rails-owned.
  def compat_admin_proxy_path?(path)
    path.start_with?("/admin/") || path == "/auth/admin/session"
  end

  # Admin requests are authenticated by the existing Devise session in Rails,
  # then signed for v1. The browser never supplies an admin user id or secret.
  def apply_compat_admin_proxy_headers(request, uri, method)
    secret = ENV["COMPAT_ADMIN_PROXY_SECRET"].presence
    admin_user = privileged_session_user if respond_to?(:privileged_session_user, true)
    # Admin::CompatReadsController has already enforced AdminController's
    # Devise authorization. Some valid admin roles are not included in the
    # super-admin/chat-operator convenience predicate, so sign that verified
    # session rather than turning the browser read into a 502.
    admin_user ||= warden.authenticate(scope: :user) if respond_to?(:warden, true)
    raise "COMPAT_ADMIN_PROXY_SECRET is required for admin compat requests" if secret.blank?
    raise "Admin session is required for admin compat requests" unless admin_user

    timestamp = (Time.now.to_f * 1000).to_i.to_s
    # V1 verifies the path after the compat prefix has been mounted.
    compat_path = uri.path.start_with?("/v1/compat/") ? uri.path : "/v1/compat#{uri.path}"
    payload = [timestamp, admin_user.id, method, compat_path].join(".")
    request["X-Compat-Admin-User-Id"] = admin_user.id.to_s
    request["X-Compat-Admin-Timestamp"] = timestamp
    request["X-Compat-Admin-Signature"] = OpenSSL::HMAC.hexdigest("SHA256", secret, payload)
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
