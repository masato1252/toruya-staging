require "rails_helper"
require "message_encryptor"

RSpec.describe SocialAccounts::Save do
  let(:user) { FactoryBot.create(:user) }
  let(:channel_id) { "channel_id".freeze }
  let(:channel_token) { "channel_token".freeze }
  let(:channel_secret) { "channel_secret".freeze }
  let(:label) { "Label".freeze }
  let(:basic_id) { "Basic id".freeze }
  let(:social_account) {}

  let(:args) do
    {
      user: user,
      social_account: social_account,
      channel_id: channel_id,
      channel_token: channel_token,
      channel_secret: channel_secret,
      label: label,
      basic_id: basic_id
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    context "when there is no social_accounts before" do
      it "creates a new social_account" do
        expect(SocialAccounts::RichMenus::CustomerReservations).to receive(:run).and_return(double(invalid?: false, result: double))

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

      it "updates existing social_account" do
        expect(SocialAccounts::RichMenus::CustomerReservations).to receive(:run).with(social_account: social_account).and_return(double(invalid?: false, result: double))

        expect {
          outcome
        }.to change {
          social_account.reload.channel_token
        }.and change {
          social_account.reload.channel_secret
        }.and change {
          social_account.reload.channel_id
        }
      end
    end
  end
end
