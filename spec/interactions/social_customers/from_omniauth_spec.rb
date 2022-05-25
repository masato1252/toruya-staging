# frozen_string_literal: true

require "rails_helper"
require "message_encryptor"

RSpec.describe SocialCustomers::FromOmniauth, :with_line do
  let(:profile) { FactoryBot.create(:profile) }
  let(:social_account) { FactoryBot.create(:social_account, user: profile.user) }
  let(:who) { nil }
  let(:args) do
    {
      auth: OmniAuth::AuthHash.new({
        provider: "line",
        uid: SecureRandom.uuid,
        info: {
          name: "name",
          image: 'https://image.url'
        },
      }),
      param: {
        "oauth_social_account_id": MessageEncryptor.encrypt(social_account.id)
      },
      who: who
    }
  end
  let(:outcome) { described_class.run!(args) }

  describe "#execute" do
    it "creates a social customer" do
      expect {
        outcome
      }.to change {
        SocialCustomer.count
      }.by(1)
    end

    context "when user is owner themself" do
      let(:who) { CallbacksController::SHOP_OWNER_CUSTOMER_SELF }

      it "creates a customer, as well" do
        expect {
          outcome
        }.to change {
          SocialCustomer.count
        }.by(1).and change {
          Customer.count
        }.by(1)

        # Prove socail customer connected with a customer
        expect(social_account.social_customers.last.customer).to eq(social_account.user.customers.last)
      end
    end
  end
end
