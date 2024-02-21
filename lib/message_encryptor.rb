# frozen_string_literal: true

module MessageEncryptor
  def self.encrypt(message, expires_at: nil)
    Base64.urlsafe_encode64(crypt.encrypt_and_sign(message, expires_at:))
  end

  def self.decrypt(encrypted_content)
    decode64_hash = Base64.urlsafe_decode64(encrypted_content)
    crypt.decrypt_and_verify(decode64_hash)
  rescue StandardError
    crypt.decrypt_and_verify(encrypted_content)
  end

  def self.crypt
    ActiveSupport::MessageEncryptor.new(Rails.application.secrets.message_encryptor_key[0..31], cipher: 'aes-256-cbc')
  end
end
