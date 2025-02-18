# frozen_string_literal: true

module Notifiers
  module Users
    module Notifications
      class ShopSettingsReminder < Base
        deliver_by_priority [:line, :sms, :email]
        validate :receiver_should_be_user

        def message
          I18n.t("notifier.shop_settings_reminder.message", setting_url: url_helpers.lines_user_bot_sign_up_url(social_service_user_id: receiver.social_user.social_service_user_id), trial_end_date: receiver.subscription.trial_expired_date.to_s)
        end

        private

        def deliverable
          !receiver&.profile&.company_address_details&.present?
        end
      end
    end
  end
end
