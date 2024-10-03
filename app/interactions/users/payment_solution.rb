module Users
  class PaymentSolution < ActiveInteraction::Base
    object :user
    string :provider, default: nil

    def execute
      case provider
      when AccessProvider.providers[:stripe_connect]
        if user.stripe_provider
          { solution: user.stripe_provider.provider, stripe_key: user.stripe_provider.publishable_key }
        else
          {}
        end
      when AccessProvider.providers[:square]
        if user.square_provider
          result = user.square_client.locations.list_locations

          if result.data
            square_location_id = result.data[:locations].last[:id]

            { solution: user.square_provider.provider, square_app_id: Rails.application.secrets.square_app_id, square_location_id: square_location_id }
          else
            {}
          end
        else
          {}
        end
      else
        {}
      end
    end
  end
end