# frozen_string_literal: true

require "rails_helper"
require "message_encryptor"

RSpec.describe SocialCustomers::FromOmniauth, :with_line do
  let(:profile) { FactoryBot.create(:profile) }
  let(:social_account) { FactoryBot.create(:social_account, user: profile.user) }
  let(:who) { nil }
  let(:uid) { SecureRandom.uuid }
  let(:args) do
    {
      auth: OmniAuth::AuthHash.new({
        provider: "line",
        uid: uid,
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

        # Prove social customer connected with a customer
        expect(social_account.social_customers.last.customer).to eq(social_account.user.customers.last)
      end
    end

    context "when a owner customer exists" do
      let!(:existing_owner_customer) { FactoryBot.create(:social_customer, user_id: social_account.user_id, social_user_id: uid, social_account_id: social_account.id, is_owner: true) }

      context "when a owner customer login by a normal customer(from booking page or online service)" do
        it "is still a owner customer" do
          expect {
            outcome
          }.to change {
            SocialCustomer.count
          }.by(0)
          expect(existing_owner_customer.reload.is_owner).to eq(true)
        end
      end
    end
  end
end
