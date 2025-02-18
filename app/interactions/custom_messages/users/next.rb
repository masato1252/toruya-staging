# frozen_string_literal: true

require "google/drive"

module CustomMessages
  module Users
    class Next < ActiveInteraction::Base
      object :custom_message, default: nil
      object :receiver, class: User
      boolean :schedule_right_away, default: false
      string :scenario, default: nil
      integer :nth_time, default: nil

      validate :validate_next_scenario
      validates :scenario, inclusion: { in: CustomMessages::Users::Template::SCENARIOS }, allow_nil: true
      DEFAULT_NOTIFICATION_HOUR = 9

      def execute
        # Ensure all time operations use the customer's timezone
        user_timezone = ::LOCALE_TIME_ZONE[receiver.locale] || "Asia/Tokyo"

        Time.use_zone(user_timezone) do
          if schedule_right_away
            send_schedule_message(custom_message)
          elsif next_custom_messages.exists?
            next_custom_messages.find_each do |next_custom_message|
              send_schedule_message(next_custom_message)
            end
          end
        end
      end

      private

      def send_schedule_message(message)
        schedule_at = scenario_start_at.advance(days: message.after_days).change(hour: DEFAULT_NOTIFICATION_HOUR, min: rand(5), sec: rand(59))

        if schedule_at > Time.current || message.after_days == 0
          Notifiers::Users::CustomMessages::Send.perform_at(
            schedule_at: schedule_at,
            scenario_start_at: scenario_start_at,
            custom_message: message,
            receiver: receiver,
          )

          log_health_check(schedule_at)
        end
      end

      def next_custom_messages
        return @next_custom_messages if defined?(@next_custom_messages)

        @next_custom_messages = CustomMessage.scenario_of(nil, user_scenario, nth_time_message).where(locale: receiver.locale).order(content_type: :desc)
        after_days = @next_custom_messages.where("after_days > ?", custom_message&.after_days || -100).first&.after_days

        @next_custom_messages =
          if after_days
            @next_custom_messages.where(after_days: after_days)
          else
            @next_custom_messages.none
          end

        @next_custom_messages
      end

      def validate_next_scenario
        if custom_message && scenario
          errors.add(:custom_message, :invalid_params)
        end

        if !custom_message && !scenario
          errors.add(:custom_message, :invalid_params)
        end

        if (!nth_time && scenario) || (nth_time && !scenario)
          errors.add(:custom_message, :invalid_params)
        end
      end

      def scenario_start_at
        case user_scenario
        when CustomMessages::Users::Template::USER_SIGN_UP
          receiver.created_at
        else
          Time.current
        end
      end

      def user_scenario
        scenario || custom_message.scenario
      end

      def nth_time_message
        nth_time || custom_message.nth_time
      end

      def log_health_check(schedule_at)
        # https://docs.google.com/spreadsheets/d/1aKZ35SIno9Ia1B2q-m8SLej_rt_MK_SpjYYy0ebE1U0/edit?gid=2106564582#gid=2106564582
        if CustomMessages::Users::Template::HEALTH_CHECK_SCENARIOS.include?(user_scenario)
          sheet = Google::Drive.spreadsheet(google_sheet_id: "1aKZ35SIno9Ia1B2q-m8SLej_rt_MK_SpjYYy0ebE1U0", gid: 2106564582)
          new_row_number = sheet.num_rows + 1

          [receiver.class.to_s, receiver.id, schedule_at, user_scenario, nth_time_message].each_with_index do |data, index|
            sheet[new_row_number, index + 1] = data
          end
          sheet.save
        end
      end
    end
  end
end
