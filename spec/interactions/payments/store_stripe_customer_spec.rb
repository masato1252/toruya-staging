require "rails_helper"

RSpec.describe Payments::StoreStripeCustomer do
  before { StripeMock.start }
  after { StripeMock.stop }

  let(:user) { FactoryBot.create(:user) }
  let!(:subscription) { FactoryBot.create(:subscription, user: user, stripe_customer_id: stripe_customer_id) }
  let(:authorize_token) { StripeMock.create_test_helper.generate_card_token }
  let(:args) do
    {
      user: user,
      authorize_token: authorize_token
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    context "when subscription stripe_customer_id exists" do
      let(:stripe_customer_id) do
        Stripe::Customer.create({
          email: user.email,
          source: StripeMock.create_test_helper.generate_card_token
        }).id
      end

      it "update stripe customer's card" do
        outcome

        expect(outcome.result).to eq(stripe_customer_id)
        expect(Stripe::Customer.retrieve(stripe_customer_id).source).to eq(authorize_token)
      end
    end

    context "when subscription stripe_customer_id doesn't exist" do
      let(:stripe_customer_id) { nil }
      it "add stripe customer a card" do
        outcome

        customer_id = outcome.result
        expect(subscription.reload.stripe_customer_id).to eq(customer_id)
      end
    end
  end
end
