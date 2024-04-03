# frozen_string_literal: true

# TODO: cronjob weekly
module AccessProviders
  class RenewAccessToken < ActiveInteraction::Base
    object :access_provider

    def execute
      case access_provider.provider
      when "square"
        result = owner.square_client.o_auth.obtain_token(
          body: {
            client_id: Rails.application.secrets.square_app_id,
            grant_type: 'refresh_token',
            client_secret: Rails.application.secrets.square_secret_key,
            refresh_token: access_provider.raw_refresh_token
          }
        )

        if result.success?
          access_provider.update(access_token: MessageEncryptor.encrypt(result.data[:access_token]))
        else
          errors.add(:access_provider, :renew_failed)
        end
      else
        errors.add(:access_provider, :not_support)
      end
    end

    private

    def owner
      @owner ||= access_provider.user
    end
  end
end
