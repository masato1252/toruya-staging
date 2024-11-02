module CustomMessages
  module Customers
    class Create < CustomMessages::Customers::Base
      object :service, class: ApplicationRecord
      string :content
      string :scenario
      integer :after_days, default: nil
      integer :before_minutes, default: nil
      string :locale, default: -> { I18n.locale.to_s }

      validate :validate_purchased_message

      def execute
        message = CustomMessage.create(
          service: service,
          scenario: scenario,
          content: content,
          after_days: after_days,
          before_minutes: before_minutes,
          locale: locale
        )

        if message.save
          if service.is_a?(OnlineService)
            notify_service_customers(message)
          end

          if service.is_a?(BookingPage)
            notify_reservation_customers(message)
          end
        end

        message
      end

      private

      def validate_purchased_message
        if after_days.nil? && service.is_a?(OnlineService) && CustomMessage.scenario_of(service, scenario).right_away.exists?
          errors.add(:after_days, :only_allow_one_purchased_message)
        end
      end
    end
  end
end
