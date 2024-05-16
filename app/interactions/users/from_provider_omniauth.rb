require "message_encryptor"

module Users
  class FromProviderOmniauth < ActiveInteraction::Base
    object :user
    object :auth, class: OmniAuth::AuthHash
    string :provider, default: AccessProvider.providers[:stripe_connect]

    def execute
      case provider
      when AccessProvider.providers[:stripe_connect]
        access = user.stripe_provider || user.build_stripe_provider
        access.provider = auth.provider
        access.uid = auth.uid
        access.access_token = MessageEncryptor.encrypt(auth.credentials.token)
        access.publishable_key = auth.info.stripe_publishable_key
      when AccessProvider.providers[:square]
        access = user.square_provider || user.build_square_provider
        access.provider = auth.provider
        access.uid = auth.uid
        access.access_token = MessageEncryptor.encrypt(auth.credentials.token)
        access.refresh_token = MessageEncryptor.encrypt(auth.credentials.refresh_token)
      end

      access.default_payment = true if !user.access_providers.payment.exists?
      access.save
      access
    end
  end
end
