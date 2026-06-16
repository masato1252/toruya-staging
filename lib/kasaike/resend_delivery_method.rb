# frozen_string_literal: true

require "resend/mailer"
require "slack_error_notifier"

module Kasaike
  class ResendDeliveryMethod
    def initialize(settings = {})
      @delegate = Resend::Mailer.new(settings)
    end

    def deliver!(mail)
      @delegate.deliver!(mail)
    rescue Resend::Error => e
      notify_delivery_failure(e, mail) unless delivery_via_application_job?
      raise
    end

    private

    def delivery_via_application_job?
      caller_locations.any? { |location| location.path&.include?("/app/jobs/") }
    end

    def notify_delivery_failure(exception, mail)
      context = {
        source: "ActionMailer (Resend)",
        mail_to: Array(mail.to).join(", "),
        mail_subject: mail.subject
      }
      SlackErrorNotifier.notify(exception, context)
      Rollbar.error(exception, context) if defined?(Rollbar)
    end
  end
end
