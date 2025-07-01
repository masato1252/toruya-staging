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

    context "when subscription requires 3DS authentication" do
      let(:stripe_subscription_id) { 'sub_test_incomplete' }
      let(:payment_intent) do
        double('PaymentIntent',
          id: 'pi_test_requires_action',
          status: 'requires_action',
          client_secret: 'pi_test_requires_action_secret'
        )
      end
      let(:invoice) { double('Invoice', payment_intent: payment_intent) }
      let(:incomplete_subscription) do
        double('Subscription',
          id: stripe_subscription_id,
          status: 'incomplete',
          latest_invoice: invoice
        )
      end

      before do
        # Override the default Stripe::Subscription.create mock to return incomplete status
        allow(Stripe::Subscription).to receive(:create).and_return(incomplete_subscription)
      end

      it "sets relation to incomplete_payment_state when 3DS is required" do
        expect(relation).to receive(:incomplete_payment_state!).and_call_original

        outcome

        # Verify the relation state is set correctly
        expect(relation).to be_incomplete_payment_state
        expect(relation.stripe_subscription_id).to eq(stripe_subscription_id)

        # Verify the proper error is added with client_secret for 3DS handling
        expect(outcome.valid?).to be_falsey
        expect(outcome.errors.details[:relation]).to be_present

        relation_error = outcome.errors.details[:relation].find { |error| error[:error] == :requires_action }
        expect(relation_error).to be_present
        expect(relation_error[:client_secret]).to eq('pi_test_requires_action_secret')
        expect(relation_error[:stripe_subscription_id]).to eq(stripe_subscription_id)
      end

      context "with different payment_intent statuses that require action" do
        ['requires_payment_method', 'requires_confirmation', 'requires_source', 'processing', 'requires_source_action'].each do |status|
          context "when payment_intent status is #{status}" do
            let(:payment_intent) do
              double('PaymentIntent',
                id: "pi_test_#{status}",
                status: status,
                client_secret: "pi_test_#{status}_secret"
              )
            end

            it "sets relation to incomplete_payment_state" do
              expect(relation).to receive(:incomplete_payment_state!).and_call_original

              outcome

              expect(relation).to be_incomplete_payment_state
              expect(outcome.valid?).to be_falsey

              relation_error = outcome.errors.details[:relation].find { |error| error[:error] == :requires_action }
              expect(relation_error).to be_present
            end
          end
        end
      end

      context "when payment_intent is nil" do
        let(:invoice) { double('Invoice', payment_intent: nil) }

        it "handles nil payment_intent gracefully" do
          # Let's see what actually happens when payment_intent is nil
          outcome

          # Check if the operation succeeds or fails, and how
          expect(outcome.valid?).to be_falsey
          expect(outcome.errors.details[:relation]).to be_present

          # The error should be caught by the general rescue block
          relation_error = outcome.errors.details[:relation].find { |error| error[:error] == :something_wrong }
          expect(relation_error).to be_present
        end
      end

      context "when payment_intent status does not require action" do
        let(:payment_intent) do
          double('PaymentIntent',
            id: 'pi_test_failed',
            status: 'failed',
            client_secret: 'pi_test_failed_secret'
          )
        end

        it "adds subscription_incomplete error instead of requires_action" do
          outcome

          expect(outcome.valid?).to be_falsey
          expect(outcome.errors.details[:relation]).to be_present

          relation_error = outcome.errors.details[:relation].find { |error| error[:error] == :subscription_incomplete }
          expect(relation_error).to be_present
        end
      end
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
