# frozen_string_literal: true

module Tickets
  class Revert < ActiveInteraction::Base
    object :consumer, class: ApplicationRecord # ReservationCustomer
    object :customer_ticket

    def execute
      ApplicationRecord.transaction do
        customer_ticket.customer_ticket_consumers.where(consumer: consumer).destroy_all
        consumer.update_columns(customer_ticket_id: nil, nth_quota: nil)
        customer_ticket.update(consumed_quota: customer_ticket.customer_ticket_consumers.sum(:ticket_quota_consumed))
      end
    end
  end
end

