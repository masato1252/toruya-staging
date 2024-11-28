# frozen_string_literal: true

require "rails_helper"

RSpec.describe Tickets::AutoProcess do
  let(:user) { FactoryBot.create(:user) }
  let(:consumer) { FactoryBot.create(:reservation_customer, customer: customer, booking_option_ids: [product.id]) }
  let(:customer) { FactoryBot.create(:customer, user: user) }
  let(:product) { FactoryBot.create(:booking_option, ticket_quota: 3, user: user) }

  let(:args) do
    {
      customer: customer,
      product: product,
      consumer: consumer
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    it "creates a ticket for product" do
      outcome

      expect(user.tickets.single.count).to eq(1)

      ticket = user.tickets.single.first
      expect(ticket).to be_present

      customer_ticket = customer.customer_tickets.where(ticket: ticket, total_quota: product.ticket_quota, consumed_quota: 1).first
      expect(customer_ticket).to be_present
      expect(customer_ticket.customer_ticket_consumers.where(consumer: consumer, ticket_quota_consumed: 1).count).to eq(1)
    end

    context "when the same customer used ticket again" do
      it "should consume the existing customer ticket" do
        outcome # consume 1 quota, left 2
        ticket = user.tickets.single.first
        customer_ticket = customer.customer_tickets.where(ticket: ticket).take
        expect(customer_ticket.consumed_quota).to eq(1)
        expect(customer_ticket.customer_ticket_consumers.count).to eq(1)
        expect(consumer.customer_tickets.count).to eq(1)
        expect(consumer.customer_tickets).to include(customer_ticket)
        expect(consumer.nth_quota_of_product(product)).to eq(1)
        expect(consumer.booking_amount).to eq(product.amount)

        second_consumer = FactoryBot.create(:reservation_customer, customer: customer)
        described_class.run(args.merge(consumer: second_consumer)) # consume second quota, left 1
        expect(customer_ticket.reload.consumed_quota).to eq(2)
        expect(customer_ticket.customer_ticket_consumers.count).to eq(2)
        expect(second_consumer.customer_tickets).to include(customer_ticket)
        expect(second_consumer.nth_quota_of_product(product)).to eq(2)
        expect(second_consumer.booking_amount).to eq(0)

        third_consumer = FactoryBot.create(:reservation_customer, customer: customer)
        described_class.run(args.merge(consumer: third_consumer)) # consume third quota, left 0
        expect(customer_ticket.reload.consumed_quota).to eq(3)
        expect(customer_ticket).to be_completed
        expect(customer_ticket.customer_ticket_consumers.count).to eq(3)
        expect(third_consumer.customer_tickets).to include(customer_ticket)
        expect(third_consumer.nth_quota_of_product(product)).to eq(3)
        expect(third_consumer.booking_amount).to eq(0)

        new_consumer = FactoryBot.create(:reservation_customer, customer: customer, booking_option_ids: [product.id])
        described_class.run(args.merge(consumer: new_consumer)) # last ticket was consumed all
        expect(user.tickets.count).to eq(1) # use the same ticket, doesn't create a new one
        expect(customer.customer_tickets.where(ticket: ticket).count).to eq(2) # create new customer ticket
        expect(ticket.customer_tickets.count).to eq(2)
        new_customer_ticket = customer.customer_tickets.active.where(ticket: ticket).take

        expect(new_customer_ticket.consumed_quota).to eq(1)
        expect(new_customer_ticket.customer_ticket_consumers.count).to eq(1)
        expect(new_consumer.customer_tickets).to include(new_customer_ticket)
        expect(new_consumer.nth_quota_of_product(product)).to eq(1)
        expect(new_consumer.booking_amount).to eq(product.amount)
      end
    end

    context "when the product ticket was expired" do
      it "should create the new customer ticket" do
        outcome # consume 1 quota, left 2
        ticket = user.tickets.single.first
        customer_ticket = customer.customer_tickets.where(ticket: ticket, total_quota: product.ticket_quota).take
        expect(customer_ticket.consumed_quota).to eq(1)
        customer_ticket.update(expire_at: 1.day.ago) # original customer ticket expired

        described_class.run(args.merge(consumer: FactoryBot.create(:reservation_customer, customer: customer)))
        expect(user.tickets.count).to eq(1) # use the same ticket, doesn't create a new one
        expect(customer.customer_tickets.where(ticket: ticket).count).to eq(2) # create new customer ticket
        expect(ticket.customer_tickets.count).to eq(2)
        new_customer_ticket = customer.customer_tickets.active.unexpired.where(ticket: ticket).take

        expect(new_customer_ticket.consumed_quota).to eq(1)
        expect(new_customer_ticket.customer_ticket_consumers.count).to eq(1)
      end
    end

    context "when the new customer use the same product ticket" do
      it "should used the existing product ticket" do
        outcome # consume 1 quota, left 2
        ticket = user.tickets.single.first
        customer_ticket = customer.customer_tickets.where(ticket: ticket, total_quota: product.ticket_quota).take
        expect(customer_ticket.consumed_quota).to eq(1)

        new_customer = FactoryBot.create(:customer, user: user)
        new_consumer = FactoryBot.create(:reservation_customer, customer: new_customer)
        described_class.run(customer: new_customer, product: product, consumer: new_consumer)
        expect(user.tickets.count).to eq(1) # use the same ticket, doesn't create a new one
        expect(new_customer.customer_tickets.where(ticket: ticket).count).to eq(1) # create new customer ticket
        new_customer_ticket = new_customer.customer_tickets.active.unexpired.where(ticket: ticket).take

        expect(ticket.customer_tickets.count).to eq(2)
      end
    end
  end
end
