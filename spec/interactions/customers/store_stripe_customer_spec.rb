# frozen_string_literal: true

require "rails_helper"

RSpec.describe Customers::StoreStripeCustomer do
  before { StripeMock.start }
  after { StripeMock.stop }

  let(:customer) { FactoryBot.create(:customer, with_stripe: true) }
  let(:authorize_token) { StripeMock.create_test_helper.generate_card_token }
  let(:args) do
    {
      customer: customer,
      authorize_token: authorize_token
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    context "when customer already has stripe_customer_id" do
      let(:stripe_customer_id) { customer.stripe_customer_id }

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
          customer_obj = Stripe::Customer.retrieve(
            customer.stripe_customer_id,
            stripe_account: customer.user.stripe_provider.uid
          )
          expect(customer_obj.invoice_settings.default_payment_method).to eq(outcome.result)
        end
      end

      context "when SetupIntent requires 3DS authentication" do
        it "returns client_secret for 3DS handling" do
          outcome

          # Should be invalid with 3DS requirements
          expect(outcome.valid?).to be_falsey
          expect(outcome.result).to be_nil

          # Should have customer error indicating requires_action
          expect(outcome.errors.details[:customer]).to be_present
          customer_error = outcome.errors.details[:customer].find { |error| error[:error] == :requires_action }
          expect(customer_error).to be_present

          # Should return client_secret and setup_intent_id for frontend 3DS handling
          expect(customer_error[:client_secret]).to be_present
          expect(customer_error[:setup_intent_id]).to be_present
        end
      end
    end

    context "when customer doesn't have stripe_customer_id" do
      let(:customer) { FactoryBot.create(:customer) }

      before do
        # Create the necessary access provider for Stripe
        FactoryBot.create(:access_provider, :stripe, user: customer.user)
      end

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

          # Check that customer was updated with new customer ID
          customer.reload
          expect(customer.stripe_customer_id).to be_present

          # Verify the customer was created with the payment method
          customer_obj = Stripe::Customer.retrieve(
            customer.stripe_customer_id,
            stripe_account: customer.user.stripe_provider.uid
          )
          expect(customer_obj.email).to eq(customer.email)
          expect(customer_obj.invoice_settings.default_payment_method).to eq(outcome.result)
        end
      end
    end

    context "when completing 3DS authentication" do
      let(:setup_intent_id) { 'test_si_123' }
      let(:args) do
        {
          customer: customer,
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
        customer_obj = Stripe::Customer.retrieve(
          customer.stripe_customer_id,
          stripe_account: customer.user.stripe_provider.uid
        )
        expect(customer_obj.invoice_settings.default_payment_method).to eq(outcome.result)
      end
    end

    context "when there are stripe errors" do
      let(:customer) { FactoryBot.create(:customer) }

      before do
        # Create the necessary access provider for Stripe
        FactoryBot.create(:access_provider, :stripe, user: customer.user)
        allow(Stripe::PaymentMethod).to receive(:create).and_raise(
          Stripe::CardError.new("Card error", "card_declined")
        )
      end

      it "handles card errors gracefully" do
        outcome

        expect(outcome.errors[:authorize_token]).to be_present
        expect(outcome.errors[:authorize_token].first).to be_present
        expect(outcome.result).to be_nil
      end
    end

    context "when using PaymentMethod ID instead of token" do
      let(:authorize_token) { "pm_1234567890abcdef" }

      before do
        # Mock a successful SetupIntent
        allow(Stripe::SetupIntent).to receive(:create).and_return(
          double('SetupIntent',
            status: 'succeeded',
            payment_method: authorize_token,
            client_secret: 'seti_123_secret'
          )
        )
      end

      it "uses the PaymentMethod ID directly" do
        outcome

        # Should return the same PaymentMethod ID
        expect(outcome.result).to eq(authorize_token)
      end
    end
  end
end