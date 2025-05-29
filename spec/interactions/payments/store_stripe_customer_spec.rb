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
          setup_intent = double('SetupIntent',
            status: 'succeeded',
            payment_method: 'test_pm_123',
            client_secret: 'seti_123_secret'
          )
          allow(Stripe::SetupIntent).to receive(:create).and_return(setup_intent)

          # Mock PaymentMethod creation from token
          payment_method = double('PaymentMethod', id: 'test_pm_123')
          allow(Stripe::PaymentMethod).to receive(:create).and_return(payment_method)

          # Mock successful customer update
          customer = double('Customer')
          allow(Stripe::Customer).to receive(:update).and_return(customer)
        end

        it "updates existing customer with new payment method" do
          outcome

          # Should return the PaymentMethod ID
          expect(outcome.result).to eq('test_pm_123')
          expect(outcome).to be_valid
        end
      end

      context "when SetupIntent requires 3DS authentication" do
        before do
          # Mock SetupIntent requiring action
          setup_intent = double('SetupIntent',
            id: 'seti_123_test',
            status: 'requires_action',
            payment_method: nil,
            client_secret: 'seti_123_secret_requires_action'
          )
          allow(Stripe::SetupIntent).to receive(:create).and_return(setup_intent)
        end

        it "returns client_secret for 3DS handling" do
          outcome

          # Should be invalid with 3DS requirements
          expect(outcome.valid?).to be_falsey
          expect(outcome.result).to be_nil

          # Should have user error indicating requires_action
          expect(outcome.errors.details[:user]).to be_present
          user_error = outcome.errors.details[:user].find { |error| error[:error] == :requires_action }
          expect(user_error).to be_present

          # Should return client_secret for frontend 3DS handling
          expect(user_error[:client_secret]).to eq('seti_123_secret_requires_action')
        end
      end
    end

    context "when subscription doesn't have stripe_customer_id" do
      before { subscription.update!(stripe_customer_id: nil) }

      context "when SetupIntent succeeds immediately" do
        before do
          # Mock a successful SetupIntent
          setup_intent = double('SetupIntent',
            status: 'succeeded',
            payment_method: 'test_pm_123',
            client_secret: 'seti_123_secret'
          )
          allow(Stripe::SetupIntent).to receive(:create).and_return(setup_intent)

          # Mock PaymentMethod creation from token
          payment_method = double('PaymentMethod', id: 'test_pm_123')
          allow(Stripe::PaymentMethod).to receive(:create).and_return(payment_method)

          # Mock successful customer creation
          customer = double('Customer', id: 'cus_test_123', email: user.email)
          allow(Stripe::Customer).to receive(:create).and_return(customer)
          allow(Stripe::Customer).to receive(:update).and_return(customer)
        end

        it "creates stripe customer and sets up payment method" do
          outcome

          # Should return the PaymentMethod ID
          expect(outcome.result).to eq('test_pm_123')
          expect(outcome).to be_valid

          # Check that subscription was updated with new customer ID
          subscription.reload
          expect(subscription.stripe_customer_id).to eq('cus_test_123')
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
        setup_intent = double('SetupIntent',
          status: 'succeeded',
          payment_method: 'test_pm_456'
        )
        allow(Stripe::SetupIntent).to receive(:retrieve).and_return(setup_intent)

        # Mock successful customer update
        customer = double('Customer')
        allow(Stripe::Customer).to receive(:update).and_return(customer)
      end

      it "completes the setup and sets payment method as default" do
        outcome

        # Should return the PaymentMethod ID
        expect(outcome.result).to eq('test_pm_456')
        expect(outcome).to be_valid
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

