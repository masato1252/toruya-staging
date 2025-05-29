# frozen_string_literal: true

require "rails_helper"

RSpec.describe CustomerPayments::PayReservation do
  before { StripeMock.start }
  after { StripeMock.stop }
  let(:booking_amount) { 1.to_money }
  let(:customer) { FactoryBot.create(:customer, with_stripe: true) }
  let(:reservation_customer) { FactoryBot.create(:reservation_customer, :booking_option, customer: customer, booking_amount: booking_amount) }
  let(:payment_provider) { customer.user.stripe_provider }

  let(:args) do
    {
      reservation_customer: reservation_customer,
      payment_provider: payment_provider
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    it "creates a completed payment" do
      expect {
        outcome
      }.to change {
        CustomerPayment.where(customer_id: reservation_customer.customer_id, product: reservation_customer, amount_cents: booking_amount.fractional, manual: true).completed.count
      }.by(1)
    end

    context "when charge failed" do
      before do
        # Mock Stripe::PaymentIntent.create to raise a card error
        card_error = Stripe::CardError.new("Your card was declined.", "card_declined", code: "card_declined")
        allow(card_error).to receive(:json_body).and_return({
          error: {
            type: "card_error",
            code: "card_declined",
            message: "Your card was declined."
          }
        })
        allow(Stripe::PaymentIntent).to receive(:create).and_raise(card_error)
      end

      it "create a auth_failed payment record" do
        outcome

        payment = CustomerPayment.where(
          customer_id: reservation_customer.customer_id,
          product: reservation_customer,
          amount_cents: booking_amount.fractional,
          manual: true
        ).last

        expect(payment).to be_auth_failed
      end
    end
  end
end
