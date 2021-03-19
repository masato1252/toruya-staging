# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserBotLines::MessageEvent do
  let(:message_type) { "text" }
  let(:event) do
    {
      "type"=>"message",
      "replyToken"=>"49f33fecfd2a4978b806b7afa5163685",
      "source"=>{
        "userId"=>"Ua52b39df3279673c4856ed5f852c81d9",
        "type"=>"user"
      },
      "timestamp"=>1536052545913,
      "message"=>{
        "type"=> message_type,
        "id"=>"8521501055275",
        "text"=> content
      }
    }
  end
  let(:social_user) { FactoryBot.create(:social_user) }
  let(:content) { "content" }

  let(:args) do
    {
      event: event,
      social_user: social_user
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    context "when event exists" do
      it "creates a social user messages" do
        expect {
          outcome
        }.to change {
          SocialUserMessage.where(social_user: social_user, message_type: SocialUserMessage.message_types[:user]).count
        }.by(1)
      end
    end

    context "when message match keyword" do
      context "message is USER_SIGN_OUT" do
        let(:content) { described_class::USER_SIGN_OUT }

        it "disconnect user" do
          expect(SocialUsers::Disconnect).to receive(:run).with(social_user: social_user)

          outcome
        end
      end

      xcontext "message is SETTINGS" do
        let(:content) { described_class::SETTINGS }

        it "sends settings message" do
          expect(LineClient).to receive(:send).with(social_user, "設定: https://Toruya.com/lines/user_bot/settings/dashboard")

          expect {
            outcome
          }.to change {
            SocialUserMessage.where(
              social_user: social_user,
              message_type: SocialUserMessage.message_types[:bot]).count
          }.by(1)
        end
      end
    end
  end
end
