# frozen_string_literal: true

require "rails_helper"

RSpec.describe CustomerPayments::Refund do
  before do
    StripeMock.start
    CustomerPayments::PayReservation.run(reservation_customer: reservation_customer)
  end
  after { StripeMock.stop }
  let(:booking_amount) { 1.to_money }
  let(:customer) { FactoryBot.create(:customer, with_stripe: true) }
  let(:reservation_customer) { FactoryBot.create(:reservation_customer, :booking_option, customer: customer, booking_amount: booking_amount) }
  let(:customer_payment) { customer.customer_payments.completed.where(product: reservation_customer).first }

  let(:args) do
    {
      customer_payment: customer_payment,
      amount: booking_amount
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    it "creates a refunded payment" do
      expect {
        outcome
      }.to change {
        CustomerPayment.where(customer_id: reservation_customer.customer_id, product: reservation_customer, amount_cents: -booking_amount.fractional, manual: true).refunded.count
      }.by(1)

      expect(reservation_customer.reload).to be_payment_refunded
    end
  end
end
