require "rails_helper"

RSpec.describe Subscriptions::ShopFeeCharge do
  let(:shop) { FactoryBot.create(:shop, user: user) }
  let(:subscription) { FactoryBot.create(:subscription) }
  let(:user) { subscription.user }
  let(:authorize_token) { SecureRandom.hex }
  let(:stripe_customer_id) do
    Stripe::Customer.create({
      email: subscription.user.email,
      source: StripeMock.create_test_helper.generate_card_token
    }).id
  end
  let(:args) do
    {
      user: user,
      shop: shop,
      authorize_token: authorize_token
    }
  end
  let(:outcome) { described_class.run(args) }

  before do
    StripeMock.start
  end
  after { StripeMock.stop }

  describe "#execute" do
    it "create a charge with expected details" do
      allow(Payments::StoreStripeCustomer).to receive(:run).and_return(spy(invalid?: false, result: stripe_customer_id))
      allow(Notifiers::Subscriptions::ChargeShopFee).to receive(:perform_later).and_return(double(deliver_later: true))
      result = outcome.result

      expect(result.amount).to eq(Money.new(Plans::Fee::PER_SHOP_FEE, Money.default_currency.id))
      expect(result.details).to eq({
        "shop_ids" => shop.id,
        "type" => SubscriptionCharge::TYPES[:shop_fee],
        "user_name" => user.name,
        "user_email" => user.email,
      })
      expect(Payments::StoreStripeCustomer).to have_received(:run).with(user: subscription.user, authorize_token: authorize_token)
      expect(Notifiers::Subscriptions::ChargeShopFee).to have_received(:perform_later)
    end
  end
end
