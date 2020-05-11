module WebPushSubscriptions
  class Create < ActiveInteraction::Base
    object :user
    hash :subscription do
      string :endpoint
      hash :keys do
        string :p256dh
        string :auth
      end
    end

    def execute
      web_push_subscription = WebPushSubscription.create(
        user: user,
        endpoint: subscription[:endpoint],
        p256dh_key: subscription[:keys][:p256dh],
        auth_key: subscription[:keys][:auth]
      )

      if web_push_subscription.errors.present?
        errors.merge!(web_push_subscription.errors)
      end

      web_push_subscription
    end
  end
end
