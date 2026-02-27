# frozen_string_literal: true

require "slack_error_notifier"

module SlackErrorNotification
  extend ActiveSupport::Concern

  included do
    set_callback :execute, :around, :notify_slack_on_error
  end

  private

  def notify_slack_on_error
    yield
  rescue StandardError => e
    context = {
      source: "Interaction: #{self.class.name}",
      user_id: extract_id(:user) || extract_id(:subscription, :user_id),
      customer_id: extract_id(:customer) || extract_id(:relation, :customer_id) ||
                   extract_id(:online_service_customer_relation, :customer_id)
    }
    SlackErrorNotifier.notify(e, context)
    raise
  end

  def extract_id(input_name, method = :id)
    input = inputs[input_name]
    return nil unless input

    if method == :id
      input.respond_to?(:id) ? input.id : nil
    else
      input.respond_to?(method) ? input.public_send(method) : nil
    end
  rescue StandardError
    nil
  end
end
