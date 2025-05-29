# frozen_string_literal: true

require "rails_helper"

RSpec.describe CustomerPayments::Refund do
  before do
    StripeMock.start

    # Mock successful PaymentIntent creation for initial payment
    successful_payment_intent = double(
      id: "pi_test_123",
      status: "succeeded",
      as_json: {
        "id" => "pi_test_123",
        "status" => "succeeded",
        "amount" => booking_amount.fractional,
        "currency" => booking_amount.currency.iso_code
      }
    )
    allow(Stripe::PaymentIntent).to receive(:create).and_return(successful_payment_intent)

    # Mock payment method retrieval for initial payment
    allow_any_instance_of(CustomerPayments::StripePayReservation).to receive(:get_selected_payment_method).and_return("pm_test_123")

    # Mock successful refund creation
    successful_refund = double(
      status: "succeeded",
      as_json: {
        "id" => "re_test_123",
        "status" => "succeeded",
        "amount" => booking_amount.fractional,
        "charge" => "ch_test_123"
      }
    )
    allow(Stripe::Refund).to receive(:create).and_return(successful_refund)

    # Create the initial payment
    CustomerPayments::PayReservation.run(reservation_customer: reservation_customer, payment_provider: user.stripe_provider)
  end
  after { StripeMock.stop }
  let(:booking_amount) { 1.to_money }
  let(:customer) { FactoryBot.create(:customer, with_stripe: true) }
  let(:user) { customer.user }
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

    context 'when refund a bundler service' do
      before do
        # Mock successful PaymentIntent for online service purchase
        online_service_payment_intent = double(
          id: "pi_service_123",
          status: "succeeded",
          as_json: {
            "id" => "pi_service_123",
            "status" => "succeeded",
            "amount" => booking_amount.fractional,
            "currency" => booking_amount.currency.iso_code
          }
        )
        allow(Stripe::PaymentIntent).to receive(:create).and_return(online_service_payment_intent)

        # Mock payment method retrieval for online service purchase
        allow_any_instance_of(CustomerPayments::PurchaseOnlineService).to receive(:get_selected_payment_method).and_return("pm_test_123")

        CustomerPayments::PurchaseOnlineService.run(online_service_customer_relation: relation, manual: true, first_time_charge: true)
      end
      let(:bundler_service) { FactoryBot.create(:online_service, :bundler, :with_stripe, user: user) }
      let(:relation) { FactoryBot.create(:online_service_customer_relation, :one_time_payment, customer: customer, online_service: bundler_service, permission_state: :active, sale_page: sale_page) }
      let(:sale_page) { FactoryBot.create(:sale_page, :one_time_payment, product: bundler_service, user: user, selling_price_amount_cents: booking_amount) }
      let(:customer_payment) { customer.customer_payments.completed.where(product: relation).first }

      it "canceled its bundled service" do
        bundled_service_with_end_at = FactoryBot.create(:bundled_service, bundler_service: bundler_service, end_at: Time.current.tomorrow)
        bundled_service_with_forever = FactoryBot.create(:bundled_service, bundler_service: bundler_service)
        relation_with_end_at_service = FactoryBot.create(:online_service_customer_relation, :bundler_payment, online_service: bundled_service_with_end_at.online_service, customer: customer, sale_page: sale_page, permission_state: :active, expire_at: Time.current.tomorrow, bundled_service: bundled_service_with_end_at)
        relation_with_forever_service = FactoryBot.create(:online_service_customer_relation, :bundler_payment, online_service: bundled_service_with_forever.online_service, customer: customer, sale_page: sale_page, permission_state: :active, bundled_service: bundled_service_with_forever)

        outcome

        relation.reload

        expect(relation).to be_active
        expect(relation).to be_refunded_payment_state
        expect(relation_with_end_at_service.reload).to be_pending
        expect(relation_with_forever_service.reload).to be_pending
      end
    end
  end
end
