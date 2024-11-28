# frozen_string_literal: true

module Tickets
  class Revert < ActiveInteraction::Base
    object :consumer, class: ApplicationRecord # ReservationCustomer
    object :customer_ticket

    def execute
      ApplicationRecord.transaction do
        customer_ticket.customer_ticket_consumers.where(consumer: consumer).destroy_all
        consumer.customer_tickets_quota.delete(customer_ticket.id)
        consumer.booking_amount = consumer.amount_need_to_pay
        consumer.save!
        total_consumed_quota = customer_ticket.customer_ticket_consumers.sum(:ticket_quota_consumed)
        customer_ticket.update(
          state: total_consumed_quota == customer_ticket.total_quota ? :completed : :active,
          consumed_quota: total_consumed_quota
        )
      end
    end
  end
end

