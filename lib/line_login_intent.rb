# frozen_string_literal: true

require "openssl"
require "json"
require "base64"

# HMAC-signed LINE login intent — parity with toruya-next LineLoginIntent.
module LineLoginIntent
  PURPOSES = %w[
    owner_settings owner_signup shop_customer shop_owner_customer_self event doc
  ].freeze

  module_function

  def secret
    ENV["LINE_LOGIN_INTENT_SECRET"].presence ||
      Rails.application.secrets.message_encryptor_key
  end

  def create!(purpose:, return_to: nil, social_account_id: nil, event_slug: nil, doc_slug: nil,
              staff_token: nil, consultant_token: nil, locale: nil, who: nil, ttl_seconds: 300)
    raise ArgumentError, "invalid purpose" unless PURPOSES.include?(purpose.to_s)

    payload = {
      purpose: purpose.to_s,
      return_to: return_to,
      social_account_id: social_account_id,
      event_slug: event_slug,
      doc_slug: doc_slug,
      staff_token: staff_token,
      consultant_token: consultant_token,
      locale: locale,
      who: who,
      exp: Time.now.to_i + ttl_seconds
    }

    encoded = Base64.urlsafe_encode64(payload.to_json, padding: false)
    signature = sign(encoded)
    token = "#{encoded}.#{signature}"
    [token, Time.at(payload[:exp])]
  end

  def verify!(token)
    raise ArgumentError, "invalid intent token format" unless token.to_s.include?(".")

    encoded, signature = token.split(".", 2)
    expected = sign(encoded)
    unless secure_compare(signature, expected)
      raise ArgumentError, "invalid intent signature"
    end

    payload = JSON.parse(Base64.urlsafe_decode64(encoded), symbolize_names: true)
    raise ArgumentError, "invalid intent payload" unless payload[:purpose].present? && payload[:exp].is_a?(Integer)
    raise ArgumentError, "intent token expired" if payload[:exp] < Time.now.to_i

    payload
  end

  def sign(encoded)
    Base64.urlsafe_encode64(
      OpenSSL::HMAC.digest("SHA256", secret, encoded),
      padding: false
    )
  end

  def secure_compare(a, b)
    return false if a.blank? || b.blank? || a.bytesize != b.bytesize

    l = 0
    a.bytes.zip(b.bytes) { |x, y| l |= x ^ y }
    l.zero?
  end
end
