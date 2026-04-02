# frozen_string_literal: true

module Notifiers
  module Users
    class LineSettingsVerified < Base
      deliver_by_priority [:line, :sms, :email]
      validate :receiver_should_be_user

      # No default message, since all Toruya message was setup by us manually
      def message; end

      def execute
        # XXX: Send message
        super

        # 完了メッセージを即時送信（DelayedJob 経由ではなく同期実行）
        Time.use_zone(receiver.timezone) do
          immediate_templates.find_each do |cm|
            Notifiers::Users::CustomMessages::Send.run(
              schedule_at: compute_schedule_at(cm),
              scenario_start_at: Time.current,
              custom_message: cm,
              receiver: receiver
            )
          end
        end
      end

      self.nth_time_scenario = ::CustomMessages::Users::Template::LINE_SETTINGS_VERIFIED

      private

      def immediate_templates
        all_templates = CustomMessage.scenario_of(nil, nth_time_scenario, nth_time)
          .where(locale: receiver.locale)
          .order(content_type: :desc)
        first_after_days = all_templates.where("after_days > ?", -100).first&.after_days
        return CustomMessage.none unless first_after_days

        all_templates.where(after_days: first_after_days)
      end

      def compute_schedule_at(cm)
        if cm.after_days == -1
          Time.current
        else
          Time.current.advance(days: cm.after_days)
            .change(hour: ::CustomMessages::Users::Next::DEFAULT_NOTIFICATION_HOUR, min: rand(5), sec: rand(59))
        end
      end
    end
  end
end
