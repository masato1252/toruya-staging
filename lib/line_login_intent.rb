# frozen_string_literal: true

require "openssl"
require "base64"
require "json"

# HMAC-signed LINE login intent tokens (shared secret with toruya-next LineLoginIntent).
module LineLoginIntent
  DEFAULT_TTL = 300

  class VerificationError < StandardError; end

  module_function

  def secret
    ENV["LINE_LOGIN_INTENT_SECRET"].presence ||
      Rails.application.secrets.message_encryptor_key
  end

  def verify!(token)
    raise VerificationError, "Intent token missing" if token.blank?
    raise VerificationError, "LINE_LOGIN_INTENT_SECRET is not configured" if secret.blank?

    encoded, signature = token.split(".", 2)
    raise VerificationError, "Invalid intent token format" if encoded.blank? || signature.blank?

    expected = sign(encoded)
    unless ActiveSupport::SecurityUtils.secure_compare(signature, expected)
      raise VerificationError, "Invalid intent signature"
    end

    payload = JSON.parse(Base64.urlsafe_decode64(encoded))
    exp = payload["exp"].to_i
    raise VerificationError, "Intent token expired" if exp < Time.now.to_i

    payload
  rescue JSON::ParserError
    raise VerificationError, "Invalid intent payload"
  end

  def sign(encoded)
    OpenSSL::HMAC.digest("SHA256", secret, encoded).then { |digest| Base64.urlsafe_encode64(digest, padding: false) }
  end
end
