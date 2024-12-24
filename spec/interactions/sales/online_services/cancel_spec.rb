# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sales::OnlineServices::Cancel do
  before { StripeMock.start }
  after { StripeMock.stop }
  let(:subscription) { FactoryBot.create(:subscription, :with_stripe) }
  let(:user) { subscription.user }
  let(:customer) { FactoryBot.create(:customer, user: user, with_stripe: true) }

  let(:args) do
    {
      relation: relation
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    context "when relation is assignment" do
      let(:online_service) { FactoryBot.create(:online_service, user: customer.user) }
      let(:relation) { FactoryBot.create(:online_service_customer_relation, :assignment, customer: customer, online_service: online_service) }

      it "updates relation states" do
        outcome

        expect(relation).to be_pending
        expect(relation).to be_canceled_payment_state
      end
    end

    context "when online_service is a subscription" do
      let(:relation) { FactoryBot.create(:online_service_customer_relation, :monthly_payment, :stripe_subscribed, customer: customer, permission_state: :active) }

      context "when online_service is a regular subscription" do
        it "still active but expire at is end of period" do
          expect {
            outcome
          }.to change {
            CustomerPayment.where(product: relation).count
          }.by(1)

          expect(outcome.result).to be_active
          expect(outcome.result.expire_at).to be_present
          expect(outcome.result).to be_canceled_payment_state
        end
      end

      context "when online_service is a subscription bundler" do
        let(:bundler_service) { FactoryBot.create(:online_service, :bundler, :with_stripe, user: user) }
        let(:relation) { FactoryBot.create(:online_service_customer_relation, :monthly_payment, :stripe_subscribed, customer: customer, online_service: bundler_service, permission_state: :active, sale_page: sale_page) }
        let(:sale_page) { FactoryBot.create(:sale_page, :recurring_payment, product: bundler_service, user: user) }

        it "still active but expire at is end of period and expires bundled services" do
          bundled_service_with_end_at = FactoryBot.create(:bundled_service, bundler_service: bundler_service, end_at: Time.current.tomorrow)
          bundled_service_with_forever = FactoryBot.create(:bundled_service, bundler_service: bundler_service)
          bundled_service_with_subscription = FactoryBot.create(:bundled_service, bundler_service: bundler_service, subscription: true)
          relation_with_end_at_service = FactoryBot.create(:online_service_customer_relation, :bundler_payment, online_service: bundled_service_with_end_at.online_service, customer: customer, sale_page: sale_page, permission_state: :active, expire_at: Time.current.tomorrow, bundled_service: bundled_service_with_end_at)
          relation_with_forever_service = FactoryBot.create(:online_service_customer_relation, :bundler_payment, online_service: bundled_service_with_forever.online_service, customer: customer, sale_page: sale_page, permission_state: :active, bundled_service: bundled_service_with_forever)
          relation_with_subscription_service = FactoryBot.create(:online_service_customer_relation, :bundler_payment, online_service: bundled_service_with_subscription.online_service, customer: customer, sale_page: sale_page, permission_state: :active, bundled_service: bundled_service_with_subscription)

          outcome

          relation.reload
          expect(relation).to be_active
          expect(relation.expire_at).to be_present
          expect(relation.stripe_subscription_id).to be_nil
          expect(relation_with_end_at_service.reload).to be_active
          expect(relation_with_end_at_service.expire_at).to eq(relation.expire_at)
          expect(relation_with_forever_service.reload).to be_active
          expect(relation_with_forever_service.expire_at).to eq(relation.expire_at)
          expect(relation_with_subscription_service.reload).to be_active
          expect(relation_with_subscription_service.expire_at).to eq(relation.expire_at)
        end
      end
    end

    context "when online_service is a bundler" do
      let(:bundler_service) { FactoryBot.create(:online_service, :bundler, :with_stripe, user: user) }
      let(:relation) { FactoryBot.create(:online_service_customer_relation, :one_time_payment, customer: customer, online_service: bundler_service, permission_state: :active, sale_page: sale_page) }
      let(:sale_page) { FactoryBot.create(:sale_page, :one_time_payment, product: bundler_service, user: user) }

      it "pends itself and pend bundled services" do
        bundled_service_with_end_at = FactoryBot.create(:bundled_service, bundler_service: bundler_service, end_at: Time.current.tomorrow)
        bundled_service_with_forever = FactoryBot.create(:bundled_service, bundler_service: bundler_service)
        relation_with_end_at_service = FactoryBot.create(:online_service_customer_relation, :bundler_payment, online_service: bundled_service_with_end_at.online_service, customer: customer, sale_page: sale_page, permission_state: :active, expire_at: Time.current.tomorrow, bundled_service: bundled_service_with_end_at)
        relation_with_forever_service = FactoryBot.create(:online_service_customer_relation, :bundler_payment, online_service: bundled_service_with_forever.online_service, customer: customer, sale_page: sale_page, permission_state: :active, bundled_service: bundled_service_with_forever)

        outcome

        relation.reload
        expect(relation).to be_pending
        expect(relation_with_end_at_service.reload).to be_pending
        expect(relation_with_forever_service.reload).to be_pending
      end
    end

    context "when online_service is a regular product" do
      let(:service) { FactoryBot.create(:online_service, :with_stripe, user: user) }
      let(:relation) { FactoryBot.create(:online_service_customer_relation, :one_time_payment, customer: customer, permission_state: :active, online_service: service, sale_page: sale_page) }
      let(:sale_page) { FactoryBot.create(:sale_page, :one_time_payment, product: service, user: user) }

      it "pends itself" do
        outcome

        relation.reload
        expect(relation).to be_pending
      end
    end
  end
end
