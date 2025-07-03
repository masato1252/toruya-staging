# frozen_string_literal: true

require "rails_helper"

RSpec.describe CustomerPayments::PurchaseOnlineService do
  before { StripeMock.start }
  after { StripeMock.stop }
  let(:subscription) { FactoryBot.create(:subscription, :with_stripe) }
  let(:customer) { FactoryBot.create(:customer, user: subscription.user, with_stripe: true) }
  let(:relation) { FactoryBot.create(:online_service_customer_relation, :one_time_payment, customer: customer) }
  let(:online_service_customer_price) {}
  let(:first_time_charge) { false }
  let(:manual) { false }

  let(:args) do
    {
      online_service_customer_relation: relation,
      online_service_customer_price: online_service_customer_price,
      first_time_charge: first_time_charge,
      manual: manual
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    before do
      # Mock successful PaymentIntent creation for most tests
      successful_payment_intent = double(
        id: "pi_test_123",
        status: "succeeded",
        as_json: {
          "id" => "pi_test_123",
          "status" => "succeeded",
          "amount" => relation.price_details.first.amount_with_currency.fractional,
          "currency" => customer.user.currency
        }
      )
      allow(Stripe::PaymentIntent).to receive(:create).and_return(successful_payment_intent)

      # Mock payment method retrieval
      allow_any_instance_of(described_class).to receive(:get_selected_payment_method).and_return("pm_test_123")
    end

    context "when it is first time charge" do
      let(:first_time_charge) { true }
      let(:manual) { true }

      it "creates a completed payment" do
        expect {
          outcome
        }.to change {
          CustomerPayment.where(
            customer: relation.customer,
            product: relation,
            amount_cents: relation.price_details.first.amount_with_currency.fractional,
            amount_currency: customer.user.currency,
            manual: manual
          ).completed.count
        }.by(1)
        expect(relation).to be_paid_payment_state
      end

      context "when it does not pay all the amount yet" do
        let(:relation) { FactoryBot.create(:online_service_customer_relation, :multiple_times_payment, customer: customer) }

        it "mark relation as partial paid" do
          expect {
            outcome
          }.to change {
            CustomerPayment.where(
              customer: relation.customer,
              product: relation,
              amount_cents: relation.price_details.first.amount_with_currency.fractional,
              amount_currency: customer.user.currency,
              manual: manual
            ).completed.count
          }.by(1)
          expect(relation).to be_partial_paid_payment_state
        end
      end

      context "when this charge order was paid" do
        let!(:paid_payment) { FactoryBot.create(:customer_payment, :completed, product: relation, customer: customer, order_id: relation.price_details.first.order_id) }

        it "returns existing paid payment" do
          expect {
            outcome
          }.not_to change {
            CustomerPayment.where(
              customer: relation.customer,
              product: relation,
              amount_cents: relation.price_details.first.amount_with_currency.fractional,
              amount_currency: customer.user.currency,
              manual: manual
            ).completed.count
          }
          expect(outcome.result).to eq(paid_payment)
        end
      end

      context "when there is an existing active payment with same order_id" do
        let!(:active_payment) do
          FactoryBot.create(
            :customer_payment,
            :active,
            product: relation,
            customer: customer,
            order_id: relation.price_details.first.order_id,
            amount: relation.price_details.first.amount_with_currency,
            manual: manual
          )
        end

        it "reuses existing active payment and processes it through Stripe" do
          expect {
            outcome
          }.not_to change {
            CustomerPayment.where(
              customer: relation.customer,
              product: relation,
              order_id: relation.price_details.first.order_id
            ).count
          }
          # Should return the same payment object (reloaded)
          expect(outcome.result.id).to eq(active_payment.id)
        end

        it "calls Stripe PaymentIntent.create to complete the active payment" do
          expect(Stripe::PaymentIntent).to receive(:create).and_call_original
          outcome
        end

        it "completes the active payment after Stripe processing" do
          result_payment = outcome.result
          expect(result_payment.id).to eq(active_payment.id)
          expect(result_payment).to be_completed  # Should be completed after Stripe processing
        end
      end
    end

    # specific charge which order id
    context "when this is specific online_service_customer_price" do
      let(:relation) { FactoryBot.create(:online_service_customer_relation, :multiple_times_payment, customer: customer) }
      let(:order_id) { relation.price_details.last.order_id }
      let(:online_service_customer_price) { FactoryBot.build(:online_service_customer_price, order_id: order_id) }

      it "charges the specific price" do
        expect {
          outcome
        }.to change {
          CustomerPayment.where(
            customer: relation.customer,
            product: relation,
            amount_cents: online_service_customer_price.amount_with_currency.fractional,
            amount_currency: customer.user.currency,
            manual: manual,
            order_id: order_id
          ).completed.count
        }.by(1)
      end

      context "when there is an existing active payment with same order_id for specific price" do
        let!(:active_payment) do
          FactoryBot.create(
            :customer_payment,
            :active,
            product: relation,
            customer: customer,
            order_id: order_id,
            amount: online_service_customer_price.amount_with_currency,
            manual: manual
          )
        end

        it "reuses existing active payment for the specific order and processes it through Stripe" do
          expect {
            outcome
          }.not_to change {
            CustomerPayment.where(
              customer: relation.customer,
              product: relation,
              order_id: order_id
            ).count
          }
          # Should return the same payment object (reloaded)
          expect(outcome.result.id).to eq(active_payment.id)
          expect(outcome.result).to be_completed  # Should be completed after Stripe processing
        end
      end
    end

    context "when it is not first time charge" do
      it "notifies customer when they where charged successfully" do
        allow(Notifiers::Customers::CustomerPayments::NotFirstTimeChargeSuccessfully).to receive(:run)

        outcome

        expect(Notifiers::Customers::CustomerPayments::NotFirstTimeChargeSuccessfully).to have_received(:run).with(
          receiver: customer,
          customer_payment: CustomerPayment.completed.last
        )
      end
    end

    context "when charge failed" do
      before do
        # Mock failed PaymentIntent creation that raises a Stripe error
        allow(Stripe::PaymentIntent).to receive(:create).and_raise(
          Stripe::CardError.new("Your card was declined.", "card_declined", json_body: { error: { code: "card_declined", message: "Your card was declined." } })
        )

        # Mock payment method retrieval
        allow_any_instance_of(described_class).to receive(:get_selected_payment_method).and_return("pm_test_123")
      end

      it "create a auth_failed payment record" do
        outcome

        payment = CustomerPayment.where(
          customer: relation.customer,
          product: relation,
          amount_cents: relation.price_details.first.amount_with_currency.fractional,
          amount_currency: customer.user.currency,
          manual: manual,
        ).last

        expect(payment).to be_auth_failed
      end

      context "when this is charged automatically" do
        let(:manual) { false }

        it "notifies owner" do
          allow(Notifiers::Users::CustomerPayments::ChargeFailedToOwner).to receive(:run)

          outcome

          payment = CustomerPayment.auth_failed.last
          expect(Notifiers::Users::CustomerPayments::ChargeFailedToOwner).to have_received(:run).with(
            receiver: customer.user,
            customer_payment: payment
          )
        end

        it "notifies customer" do
          allow(Notifiers::Customers::CustomerPayments::ChargeFailedToCustomer).to receive(:run)

          outcome

          payment = CustomerPayment.auth_failed.last
          expect(Notifiers::Customers::CustomerPayments::ChargeFailedToCustomer).to have_received(:run).with(
            receiver: customer,
            customer_payment: payment
          )
        end
      end
    end
  end
end
