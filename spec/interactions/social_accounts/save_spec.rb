require "rails_helper"
require "message_encryptor"

RSpec.describe SocialAccounts::Save do
  let(:user) { FactoryBot.create(:user) }
  let(:channel_id) { "channel_id".freeze }
  let(:channel_token) { "channel_token".freeze }
  let(:channel_secret) { "channel_secret".freeze }

  let(:args) do
    {
      user: user,
      channel_id: channel_id,
      channel_token: channel_token,
      channel_secret: channel_secret
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    context "when there is no social_accounts before" do
      it "creates a new social_account" do
        expect {
          outcome
        }.to change {
          user.social_accounts.where(channel_id: channel_id).count
        }.by(1)
      end
    end

    context "when there is existing social_account" do
      let!(:social_account) { FactoryBot.create(:social_account) }
      let(:user) { social_account.user }
      let(:channel_id) { social_account.channel_id }

      it "updates existing social_account" do
        expect {
          outcome
        }.to change {
          social_account.reload.channel_token
        }.and change {
          social_account.reload.channel_secret
        }
      end
    end
  end
end
