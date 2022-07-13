# frozen_string_literal: true

require "rails_helper"

RSpec.describe OnlineServiceCustomerRelations::Unsubscribe do
  before { StripeMock.start }
  after { StripeMock.stop }
  let(:subscription) { FactoryBot.create(:subscription, :with_stripe) }
  let(:customer) { FactoryBot.create(:customer, user: subscription.user, with_stripe: true) }
  let(:user) { customer.user }

  let(:args) do
    {
      relation: relation
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    context "when relation was permission pending" do
      # pending permission relation
      let(:relation) { FactoryBot.create(:online_service_customer_relation, :monthly_payment, :stripe_subscribed, :expired, customer: customer, permission_state: :pending) }

      context "when stripe_subscribed was still active" do
        it "cancels old stripe subscription" do
          Timecop.freeze(Time.current) do
            old_stripe_subscription_id = relation.stripe_subscription_id

            outcome

            expect(Stripe::Subscription.retrieve(old_stripe_subscription_id).status).to eq(STRIPE_SUBSCRIPTION_STATUS[:canceled])
            expect(outcome.result).to be_failed_payment_state
            expect(outcome.result).to be_pending
            expect(outcome.result.stripe_subscription_id).to be_nil
          end
        end
      end

      context "when stripe_subscribed was canceled" do
        before do
          Stripe::Subscription.delete(
            relation.stripe_subscription_id,
            {},
            stripe_account: customer.user.stripe_provider.uid
          )
        end

        it "does nothing" do
          outcome

          expect(outcome.result).to eq(relation)
        end
      end
    end

    context "when relation was available" do
      let(:relation) { FactoryBot.create(:online_service_customer_relation, :monthly_payment, :stripe_subscribed, customer: customer, permission_state: :active) }

      context "when stripe_subscribed was active" do
        it "cancels old stripe subscription" do
          Timecop.freeze(Time.current) do
            old_stripe_subscription_id = relation.stripe_subscription_id

            outcome

            expect(Stripe::Subscription.retrieve(old_stripe_subscription_id).status).to eq(STRIPE_SUBSCRIPTION_STATUS[:canceled])
            expect(outcome.result.expire_at).to be_nil
            expect(outcome.result).to be_failed_payment_state
            expect(outcome.result).to be_pending
            expect(outcome.result.stripe_subscription_id).to be_nil
          end
        end

        context 'when the subscribed service is a bundler service' do
          let(:relation) { FactoryBot.create(:online_service_customer_relation, :monthly_payment, :stripe_subscribed, customer: customer, online_service: bundler_service, permission_state: :active, sale_page: sale_page) }
          let(:sale_page) { FactoryBot.create(:sale_page, :recurring_payment, product: bundler_service, user: user) }
          let(:bundler_service) { FactoryBot.create(:online_service, :bundler, :with_stripe, user: user) }

          it 'stops the subscribed bundled service as well' do
            bundled_service_with_end_at = FactoryBot.create(:bundled_service, bundler_service: bundler_service, end_at: Time.current.tomorrow)
            bundled_service_with_forever = FactoryBot.create(:bundled_service, bundler_service: bundler_service)
            bundled_service_with_subscription = FactoryBot.create(:bundled_service, bundler_service: bundler_service, subscription: true)
            relation_with_end_at_service = FactoryBot.create(:online_service_customer_relation, :bundler_payment, online_service: bundled_service_with_end_at.online_service, customer: customer, sale_page: sale_page, permission_state: :active, expire_at: Time.current.tomorrow, bundled_service: bundled_service_with_end_at)
            relation_with_forever_service = FactoryBot.create(:online_service_customer_relation, :bundler_payment, online_service: bundled_service_with_forever.online_service, customer: customer, sale_page: sale_page, permission_state: :active, bundled_service: bundled_service_with_forever)
            relation_with_subscription_service = FactoryBot.create(:online_service_customer_relation, :bundler_payment, online_service: bundled_service_with_subscription.online_service, customer: customer, sale_page: sale_page, permission_state: :active, bundled_service: bundled_service_with_subscription)

            outcome

            expect(outcome.result).to be_pending
            expect(outcome.result.stripe_subscription_id).to be_nil
            expect(relation_with_end_at_service.reload).to be_active
            expect(relation_with_forever_service.reload).to be_active
            expect(relation_with_subscription_service.reload).to be_pending
          end
        end
      end

      context "when stripe_subscribed was canceled" do
        before do
          Stripe::Subscription.delete(
            relation.stripe_subscription_id,
            {},
            stripe_account: customer.user.stripe_provider.uid
          )
        end

        it "cancels old stripe subscription" do
          Timecop.freeze(Time.current) do
            old_stripe_subscription_id = relation.stripe_subscription_id

            outcome

            expect(Stripe::Subscription.retrieve(old_stripe_subscription_id).status).to eq(STRIPE_SUBSCRIPTION_STATUS[:canceled])
            expect(outcome.result.expire_at).to be_nil
            expect(outcome.result).to be_failed_payment_state
            expect(outcome.result).to be_pending
            expect(outcome.result.stripe_subscription_id).to be_nil
          end
        end
      end
    end
  end
end
