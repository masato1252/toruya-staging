# frozen_string_literal: true

module Notifiers
  module Users
    module Notifications
      class UserSignedUpAsStaff < Base
        deliver_by_priority [:line, :sms, :email]
        object :owner, class: User

        validate :receiver_should_be_user

        def message
          I18n.t("notifier.staff_user_sign_up.message", trial_end_date: receiver.subscription.trial_expired_date.to_s, owner_name: owner.name)
        end
      end
    end
  end
end
