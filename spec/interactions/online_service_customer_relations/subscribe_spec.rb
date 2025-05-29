# frozen_string_literal: true

require "rails_helper"

RSpec.describe OnlineServiceCustomerRelations::Subscribe do
  before { StripeMock.start }
  after { StripeMock.stop }
  let(:subscription) { FactoryBot.create(:subscription, :with_stripe) }
  let(:customer) { FactoryBot.create(:customer, user: subscription.user, with_stripe: true) }
  let(:relation) { FactoryBot.create(:online_service_customer_relation, :monthly_payment, customer: customer) }

  let(:args) do
    {
      relation: relation
    }
  end
  let(:outcome) { described_class.run(args) }

  # Mock Stripe subscriptions to handle payment_settings parameter that StripeMock doesn't support
  before do
    original_create = Stripe::Subscription.method(:create)
    allow(Stripe::Subscription).to receive(:create) do |params, *args|
      # Remove payment_settings parameter which StripeMock doesn't support
      cleaned_params = params.dup
      cleaned_params.delete(:payment_settings)

      # Call the original StripeMock implementation
      subscription = original_create.call(cleaned_params, *args)

      # Ensure it has the properties our interaction expects
      allow(subscription).to receive(:status).and_return('active')
      allow(subscription).to receive(:latest_invoice).and_return(double('Invoice', payment_intent: nil))

      subscription
    end
  end

  describe "#execute" do
    it "updates relation payment state to paid" do
      outcome

      expect(relation.stripe_subscription_id).to be_present
      expect(relation).to be_paid_payment_state
    end

    context "when relation was not available" do
      let(:relation) { FactoryBot.create(:online_service_customer_relation, :monthly_payment, :stripe_subscribed, :expired, customer: customer, permission_state: :active) }

      it "cancels old stripe subscription and create a new one" do
        old_stripe_subscription_id = relation.stripe_subscription_id

        expect {
          outcome
        }.to change {
          relation.stripe_subscription_id
        }

        expect(Stripe::Subscription.retrieve(old_stripe_subscription_id).status).to eq("canceled")
      end
    end

    context "when relation was legal to access" do
      context "when its stripe subscription is still active" do
        context "when relation is accessible" do
          let(:relation) { FactoryBot.create(:online_service_customer_relation, :stripe_subscribed, :monthly_payment, customer: customer, permission_state: :active) }

          it "does nothing" do
            expect {
              outcome
            }.not_to change {
              relation.stripe_subscription_id
            }
          end
        end

        context "when relation is available" do
          let(:service_start_yet) { FactoryBot.build(:online_service, start_at: Time.now.tomorrow) }
          let(:relation) { FactoryBot.create(:online_service_customer_relation, :stripe_subscribed, :monthly_payment, customer: customer, permission_state: :active, online_service: service_start_yet) }

          it "does nothing" do
            expect {
              outcome
            }.not_to change {
              relation.stripe_subscription_id
            }
          end
        end
      end

      context "when its stripe subscription is canceled" do
        let(:relation) { FactoryBot.create(:online_service_customer_relation, :stripe_subscribed, :monthly_payment, customer: customer, permission_state: :active) }
        before do
          Stripe::Subscription.delete(
            relation.stripe_subscription_id,
            {},
            stripe_account: customer.user.stripe_provider.uid
          )
        end

        it "subscribes new one" do
          expect {
            outcome
          }.to change {
            relation.stripe_subscription_id
          }
        end
      end
    end
  end
end
