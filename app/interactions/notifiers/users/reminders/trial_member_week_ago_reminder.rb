# frozen_string_literal: true

module Notifiers
  module Users
    module Reminders
      class TrialMemberWeekAgoReminder < Base
        deliver_by_priority [:line, :sms, :email], mailer: ReminderMailer, mailer_method: :trial_member_week_ago_reminder

        def message
          I18n.t(
            "notifier.reminders.trial_member_week_ago_reminder.message",
            user_name: user.name,
            signup_date: I18n.l(signup_date, format: :year_month_date),
            trial_expired_date: I18n.l(trial_expired_date, format: :year_month_date),
            plan_url: Rails.application.routes.url_helpers.lines_user_bot_settings_plans_url(encrypted_user_id: MessageEncryptor.encrypt(user.id, expires_at: 2.week.from_now))
          )
        end

        private

        def signup_date
          @signup_date ||= user.created_at.to_date
        end

        def trial_expired_date
          @trial_expired_date ||= user.trial_expired_date
        end
      end
    end
  end
end
