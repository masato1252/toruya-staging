# frozen_string_literal: true

require "rails_helper"

RSpec.describe Tickets::Revert do
  let(:user) { FactoryBot.create(:user) }
  let(:customer) { FactoryBot.create(:customer, user: user) }
  let(:consumer) { FactoryBot.create(:reservation_customer, customer: customer, booking_option_ids: [product.id], customer_tickets_quota: { customer_ticket.id => { nth_quota: 1, product_id: product.id } }) }
  let(:product) { FactoryBot.create(:booking_option, ticket_quota: 3, user: user) }
  let(:customer_ticket) { FactoryBot.create(:customer_ticket, customer_id: customer.id, total_quota: product.ticket_quota, consumed_quota: 1) }
  let(:outcome) { described_class.run(consumer: consumer, customer_ticket: customer_ticket) }

  describe "#execute" do
    it "reverts the customer ticket" do
      outcome

      expect(customer_ticket.consumed_quota).to eq(0)
      expect(consumer.customer_tickets_quota).to be_empty
      expect(consumer.booking_amount).to eq(product.amount)
    end
  end
end
