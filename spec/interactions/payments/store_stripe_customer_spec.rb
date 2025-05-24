# frozen_string_literal: true

require "rails_helper"

RSpec.describe Payments::StoreStripeCustomer do
  before { StripeMock.start }
  after { StripeMock.stop }

  let(:user) { subscription.user }
  let!(:subscription) { FactoryBot.create(:subscription, :with_stripe) }
  let(:authorize_token) { StripeMock.create_test_helper.generate_card_token }
  let(:args) do
    {
      user: user,
      authorize_token: authorize_token
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    context "when subscription already has stripe_customer_id" do
      let(:stripe_customer_id) { subscription.stripe_customer_id }

      context "when SetupIntent succeeds immediately" do
        before do
          # Mock a successful SetupIntent
          allow(Stripe::SetupIntent).to receive(:create).and_return(
            double('SetupIntent',
              status: 'succeeded',
              payment_method: 'test_pm_123',
              client_secret: 'seti_123_secret'
            )
          )
        end

        it "updates existing customer with new payment method" do
          outcome

          # Should return the PaymentMethod ID
          expect(outcome.result).to start_with('test_pm_')

          # Verify the customer was updated with the new default payment method
          customer = Stripe::Customer.retrieve(stripe_customer_id)
          expect(customer.invoice_settings.default_payment_method).to eq(outcome.result)
        end
      end

      context "when SetupIntent requires 3DS authentication" do
        it "returns client_secret for 3DS handling" do
          outcome

          # Should be invalid with 3DS requirements
          expect(outcome.valid?).to be_falsey
          expect(outcome.result).to be_nil

                    # Should have user error indicating requires_action
          expect(outcome.errors.details[:user]).to be_present
          user_error = outcome.errors.details[:user].find { |error| error[:error] == :requires_action }
          expect(user_error).to be_present

          # Should return client_secret and setup_intent_id for frontend 3DS handling
          expect(user_error[:client_secret]).to be_present
          expect(user_error[:setup_intent_id]).to be_present
        end
      end
    end

    context "when subscription doesn't have stripe_customer_id" do
      before { subscription.update!(stripe_customer_id: nil) }

      context "when SetupIntent succeeds immediately" do
        before do
          # Mock a successful SetupIntent
          allow(Stripe::SetupIntent).to receive(:create).and_return(
            double('SetupIntent',
              status: 'succeeded',
              payment_method: 'test_pm_123',
              client_secret: 'seti_123_secret'
            )
          )
        end

        it "creates stripe customer and sets up payment method" do
          outcome

          # Should return the PaymentMethod ID
          expect(outcome.result).to start_with('test_pm_')

          # Check that subscription was updated with new customer ID
          subscription.reload
          expect(subscription.stripe_customer_id).to be_present

          # Verify the customer was created with the payment method
          customer = Stripe::Customer.retrieve(subscription.stripe_customer_id)
          expect(customer.email).to eq(user.email)
          expect(customer.invoice_settings.default_payment_method).to eq(outcome.result)
        end
      end
    end

    context "when completing 3DS authentication" do
      let(:setup_intent_id) { 'test_si_123' }
      let(:args) do
        {
          user: user,
          authorize_token: authorize_token,
          setup_intent_id: setup_intent_id
        }
      end

      before do
        # Mock successful SetupIntent retrieval
        allow(Stripe::SetupIntent).to receive(:retrieve).and_return(
          double('SetupIntent',
            status: 'succeeded',
            payment_method: 'test_pm_456'
          )
        )
      end

      it "completes the setup and sets payment method as default" do
        outcome

        # Should return the PaymentMethod ID
        expect(outcome.result).to eq('test_pm_456')

        # Should update customer with new default payment method
        customer = Stripe::Customer.retrieve(subscription.stripe_customer_id)
        expect(customer.invoice_settings.default_payment_method).to eq(outcome.result)
      end
    end

    context "when there are stripe errors" do
      before do
        allow(Stripe::PaymentMethod).to receive(:create).and_raise(Stripe::CardError.new("Card error", "card_declined"))
      end

      it "handles card errors gracefully" do
        outcome

        expect(outcome.errors[:user]).to be_present
        expect(outcome.errors[:user].first).to include('auth_failed')
        expect(outcome.result).to be_nil
      end
    end
  end
end

