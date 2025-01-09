# frozen_string_literal: true

module Notifiers
  module Users
    module Subscriptions
      class ChargeSuccessfully < Base
        deliver_by_priority [:line, :sms, :email], mailer: SubscriptionMailer, mailer_method: :charge_successfully

        def message
          CustomMessage.user_charge_message(user.locale)&.content.presence || I18n.t("notifier.subscriptions.charge_successfully.message", user_name: user.name)
        end
      end
    end
  end
end