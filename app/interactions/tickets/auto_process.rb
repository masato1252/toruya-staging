# frozen_string_literal: true

module Tickets
  class AutoProcess < ActiveInteraction::Base
    object :customer
    object :product, class: ApplicationRecord # BookingOption
    object :consumer, class: ApplicationRecord # ReservationCustomer
    object :selected_ticket, default: nil, class: ApplicationRecord # Ticket
    integer :quote_consumed, default: 1

    validate :validate_product
    validate :validate_consumer

    def execute
      ApplicationRecord.transaction do
        ticket = selected_ticket

        if !ticket
          if ticket_product = TicketProduct.where(product: product).take
            ticket = ticket_product.ticket
          else
            ticket = user.tickets.single.create
            ticket_product = ticket.ticket_products.create(product: product)
          end
        end

        customer_ticket = customer.customer_tickets.unexpired.active.where(ticket: ticket).take
        customer_ticket ||= customer.customer_tickets.active.build(
          ticket: ticket,
          total_quota: product.ticket_quota,
          code: random_code,
          expire_at: product.ticket_expire_time(consumer_start_time)
        )

        customer_ticket.consumed_quota = customer_ticket.consumed_quota + quote_consumed
        customer_ticket.state = :completed if customer_ticket.consumed_quota == customer_ticket.total_quota
        customer_ticket.save!

        customer_ticket.customer_ticket_consumers.create!(consumer: consumer, ticket_quota_consumed: quote_consumed)
        # Becasue one ticket only could have one product,
        # so different product would use different customer_ticket,
        # then might have different nth_quota
        consumer.update!(
          customer_tickets_quota: consumer.customer_tickets_quota.merge(
            customer_ticket.id => {
              nth_quota: customer_ticket.consumed_quota,
              product_id: product.id
            }
          )
        )

        # Recalculate the amount need to pay
        consumer.update!(booking_amount: consumer.amount_need_to_pay)
        customer_ticket
      end
    end

    private

    def user
      @user ||= customer.user
    end

    def random_code
      # TODO: Avoid dup
      random_number = SecureRandom.random_number(100_000)
      random_string = format('%05d', random_number)
    end

    def validate_product
      errors.add(:product, :invalid) if !product.ticket_enabled?
    end

    def validate_consumer
      if consumer.customer != customer
        errors.add(:consumer, :invalid)
      end
    end

    def consumer_start_time
      if consumer.is_a?(ReservationCustomer)
        consumer.reservation.start_time
      end
    end
  end
end
