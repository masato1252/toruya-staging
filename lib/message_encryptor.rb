# frozen_string_literal: true

module MessageEncryptor
  def self.encrypt(message)
    crypt.encrypt_and_sign(message)
  end

  def self.decrypt(encrypted_content)
    crypt.decrypt_and_verify(encrypted_content)
  end

  def self.crypt
    ActiveSupport::MessageEncryptor.new(Rails.application.secrets.message_encryptor_key[0..31])
  end
end
