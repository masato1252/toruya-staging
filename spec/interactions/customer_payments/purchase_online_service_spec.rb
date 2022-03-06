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
            amount_currency: Money.default_currency.iso_code,
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
              amount_currency: Money.default_currency.iso_code,
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
              amount_currency: Money.default_currency.iso_code,
              manual: manual
            ).completed.count
          }
          expect(outcome.result).to eq(paid_payment)
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
            amount_currency: Money.default_currency.iso_code,
            manual: manual,
            order_id: order_id
          ).completed.count
        }.by(1)
      end
    end

    context "when it is not first time charge" do
      it "notifies customer when they where charged successfully" do
        allow(Notifiers::CustomerPayments::NotFirstTimeChargeSuccessfully).to receive(:run)

        outcome

        expect(Notifiers::CustomerPayments::NotFirstTimeChargeSuccessfully).to have_received(:run).with(
          receiver: customer,
          customer_payment: CustomerPayment.completed.last
        )
      end
    end

    context "when charge failed" do
      before { StripeMock.prepare_card_error(:card_declined) }

      it "create a auth_failed payment record" do
        outcome

        payment = CustomerPayment.where(
          customer: relation.customer,
          product: relation,
          amount_cents: relation.price_details.first.amount_with_currency.fractional,
          amount_currency: Money.default_currency.iso_code,
          manual: manual,
        ).last

        expect(payment).to be_auth_failed
      end

      context "when this is charged automatically" do
        let(:manual) { false }

        it "notifies owner" do
          allow(Notifiers::CustomerPayments::ChargeFailedToOwner).to receive(:run)

          outcome
          expect(Notifiers::CustomerPayments::ChargeFailedToOwner).to have_received(:run).with(
            receiver: customer.user,
            customer_payment: CustomerPayment.auth_failed.last
          )
        end

        it "notifies customer" do
          allow(Notifiers::CustomerPayments::ChargeFailedToCustomer).to receive(:run)

          outcome
          expect(Notifiers::CustomerPayments::ChargeFailedToCustomer).to have_received(:run).with(
            receiver: customer,
            customer_payment: CustomerPayment.auth_failed.last
          )
        end
      end
    end
  end
end
