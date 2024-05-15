# frozen_string_literal: true

require "rails_helper"

RSpec.describe Users::FromOmniauth do
  let(:email) { Faker::Internet.email }
  let(:referral_token) {}
  let(:args) do
    {
      auth: OmniAuth::AuthHash.new({
        provider: "google_oauth2",
        uid: SecureRandom.uuid,
        info: {
          email: email
        },
        credentials: {
          token: SecureRandom.hex,
          refresh_token: SecureRandom.hex
        }
      }),
      referral_token: referral_token
    }
  end
  let(:outcome) { described_class.run!(args) }

  describe "#execute" do
    it "creates a user" do
      expect {
        outcome
      }.to change {
        User.count
      }.by(1)
    end

    context "when user is a new user" do
      it "had ranks and subscription" do
        user = outcome

        expect(user.ranks).to be_exists
        expect(user.subscription).to be_persisted
      end
    end

    context "when the existing_user came again" do
      let!(:existing_user) { FactoryBot.create(:user, email: email) }

      it "is valid" do
        expect(outcome).to be_valid
      end

      it "had ranks and subscription" do
        user = outcome

        expect(user.ranks).to be_exists
        expect(user.subscription).to be_persisted
      end
    end

    context "when new user got the same referral_token with existing user" do
      let!(:existing_user) { FactoryBot.create(:user) }
      before do
        allow(Devise).to receive(:friendly_token).and_return(
          SecureRandom.hex, # overwrite password
          existing_user.referral_token , # overwrite first referral_token assignment
          Devise.friendly_token[0,10]) # generate random token for second assignment
      end

      it "uses different referral_token from existing_user" do
        expect {
          outcome
        }.to change {
          User.count
        }.by(1)

        expect(User.last.referral_token).to_not eq(existing_user.referral_token)
      end
    end

    context "when referral_token exists" do
      let!(:referee) { FactoryBot.create(:subscription, :business).user }
      let(:referral_token) { referee.referral_token }

      context "when this is new user sign up" do
        it "creates a referral" do
          user = outcome

          expect(user.reference.referee).to eq(referee)
          expect(user.ranks).to be_exists
          expect(user.subscription).to be_persisted
        end
      end

      context "when this is a existing user" do
        let!(:existing_user) { FactoryBot.create(:user, email: email) }

        it "does NOT create a referral" do
          expect {
            outcome
          }.not_to change {
            Referral.where(referee: referee).count
          }
        end
      end
    end
  end
end
