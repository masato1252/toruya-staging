# frozen_string_literal: true

require "line_client"

module Notifiers
  class Base < ActiveInteraction::Base
    class << self
      # @deliver_by_priority would try to use one of the way to notify users base on the priority
      # Note: Need to provide the mailer and mailer_method option when delivered by email
      #
      # Examples:
      # deliver_by_priority [:sms, :email], mailer: NotificationMailer, mailer_method: :activate_staff_account
      def deliver_by_priority(notifiers, *args)
        options = args.extract_options!

        self.delivered_by_priority = notifiers
        self.mailer = options[:mailer]
        self.mailer_method = options[:mailer_method]
      end

      # deliver_by :{deliver_solution} would use the way dine to notify users
      #
      # deliver_by :line
      # deliver_by :sms
      # deliver_by :email, mailer: NotificationMailer, mailer_method: :activate_staff_account
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
    class_attribute :nth_time_scenario, instance_writer: false
    delegate :email, to: :target_email_user
    delegate :phone_number, to: :target_phone_user

    # User, StaffAccount, SocialUser, Customer, SocialCustomer
    object :receiver, class: ApplicationRecord
    object :user, default: nil # used for sending SMS
    object :customer, default: nil # used for sending SMS
    time :schedule_at, default: nil

    def execute
      return unless deliverable

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

    def target_line_user
      case receiver
      when User
        receiver.social_user
      when Customer
        receiver.social_customer
      when StaffAccount
        receiver&.user&.social_user
      else
        receiver
      end
    end

    def target_email_user
      case receiver
      when SocialUser
        receiver.user
      when SocialCustomer
        receiver.customer
      else
        receiver
      end
    end
    alias_method :target_phone_user, :target_email_user

    def message
      raise NotImplementedError, "Subclass must implement this method"
    end

    def content_type
      SocialUserMessages::Create::TEXT_TYPE
    end

    def message_scenario; end

    def nth_time_message; end

    def send_line
      I18n.with_locale(target_line_user.user&.locale || target_line_user.language) do
        case target_line_user
        when SocialUser
          outcome = SocialUserMessages::Create.run(
            social_user: target_line_user,
            content: message,
            content_type: content_type,
            scenario: message_scenario,
            nth_time: nth_time_message,
            message_type: SocialMessage.message_types[:bot],
            readed: true,
            custom_message_id: custom_message_id
          )
          errors.merge!(outcome.errors) if outcome.invalid?
        when SocialCustomer
          outcome = SocialMessages::Create.run(
            social_customer: target_line_user,
            content: message,
            content_type: content_type,
            message_type: SocialMessage.message_types[:bot],
            readed: true
          )
          errors.merge!(outcome.errors) if outcome.invalid?
        else
          LineClient.send(target_line_user, message)
        end
      end
    end

    def send_sms
      I18n.with_locale(user&.locale || customer&.locale || I18n.default_locale) do
        Sms::Create.run(
          user: user,
          customer: customer,
          message: message,
          phone_number: phone_number
        )
      end
    end

    def send_email
      I18n.with_locale(target_email_user.locale) do
        mailer.public_send(mailer_method, target_email_user).deliver_now
      end
    end

    def line?
      target_line_user.try(:social_user_id).present?
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

    def deliverable
      true
    end

    private

    def custom_message_id
      nil
    end

    def receiver_should_be_customer
      unless receiver.is_a?(Customer)
        errors.add(:receiver, :should_be_customer)
      end
    end

    def receiver_should_be_user
      unless receiver.is_a?(User)
        errors.add(:receiver, :should_be_user)
      end
    end

    def receiver_should_be_staff_account
      unless receiver.is_a?(StaffAccount)
        errors.add(:receiver, :should_be_staff_account)
      end
    end

    def receiver_should_be_consultant_account
      unless receiver.is_a?(ConsultantAccount)
        errors.add(:receiver, :should_be_consultant_account)
      end
    end

    def nth_time
      support_nth_times = CustomMessage.where(scenario: nth_time_scenario).order(nth_time: :desc).distinct(:nth_time).pluck(:nth_time)
      expected_nth_time = SocialUserMessage.sent.where(social_user: target_line_user, scenario: nth_time_scenario).distinct(:nth_time).pluck(:nth_time).length + 1

      # [4, 2, 1]
      #
      # If expected_nth_time is 5 => return 4
      # If expected_nth_time is 4 => return 4
      # If expected_nth_time is 3 => return 2
      support_nth_times.each do |nth|
        return nth if expected_nth_time >= nth
      end
    end
  end
end
