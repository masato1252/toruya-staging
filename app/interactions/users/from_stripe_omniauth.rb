require "message_encryptor"

module Users
  class FromStripeOmniauth < ActiveInteraction::Base
    object :user
    object :auth, class: OmniAuth::AuthHash

    def execute
      access = user.stripe_provider || user.build_stripe_provider
      access.provider = auth.provider
      access.uid = auth.uid
      access.access_token = MessageEncryptor.encrypt(auth.credentials.token)
      access.publishable_key = auth.info.stripe_publishable_key

      access.save
      access
    end
  end
end
