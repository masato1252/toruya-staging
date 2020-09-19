module Notifiers
  class Base < ActiveInteraction::Base
    class << self
      def deliver_by_priority(notifiers, *args)
        options = args.extract_options!

        self.delivered_by_priority = notifiers
        self.mailer = options[:mailer]
        self.mailer_method = options[:mailer_method]
      end

      def deliver_by(notifier, *args)
        options = args.extract_options!

        self.public_send("deliver_by_#{notifier}=", true)
        self.mailer ||= options[:mailer]
        self.mailer_method ||= options[:mailer_method]
      end
    end

    class_attribute :delivered_by_priority, instance_writer: false
    class_attribute :deliver_by_sms, instance_writer: false
    class_attribute :deliver_by_line, instance_writer: false
    class_attribute :deliver_by_email, instance_writer: false
    class_attribute :mailer, instance_writer: false
    class_attribute :mailer_method, instance_writer: false
    delegate :email, :phone_number, to: :receiver

    object :receiver, class: ApplicationRecord
    object :user, default: nil
    object :customer, default: nil

    def execute
      if delivered_by_priority.present?
        delivered_by_priority.each do |notifier|
          if public_send("#{notifier}?").present?
            public_send("send_#{notifier}".to_sym)

            break
          end
        end
      end

      if deliver_by_email && email?
        send_email
      end

      if deliver_by_sms && sms?
        send_sms
      end

      if deliver_by_line && line?
        send_line
      end
    end

    def message
      raise NotImplementedError, "Subclass must implement this method"
    end

    def send_line
    end

    def send_sms
      compose(
        Sms::Create,
        user: user,
        customer: customer,
        message: message,
        phone_number: phone_number
      )
    end

    def send_email
      mailer.public_send(mailer_method, receiver).deliver_now
    end

    def line?
    end

    def sms?
      phone_number.present?
    end

    def email?
      email.present?
    end

    def url_helpers
      Rails.application.routes.url_helpers
    end
  end
end
