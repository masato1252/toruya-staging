# frozen_string_literal: true

require "rails_helper"

RSpec.describe Lines::HandleEvent do
  let(:event_type) { "message" }
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
        "type"=> "text",
        "id"=>"8521501055275",
        "text"=>"??"
      }
    }
  end
  let(:social_account) { FactoryBot.create(:social_account) }

  let(:args) do
    {
      event: event,
      social_account: social_account
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    context "when message_type is message" do
      it "creates expected social_customer and executes expected event" do
        response = Net::HTTPOK.new(1.0, "200", "OK")
        expect(LineClient).to receive(:profile).and_return(response)
        expect(response).to receive(:body) { {displayName: "foo", pictureUrl: "bar"}.to_json }
        expect(Lines::MessageEvent).to receive(:run!)

        expect {
          outcome
        }.to change {
          SocialCustomer.where(
            social_account: social_account,
            user_id: social_account.user_id,
            social_user_name: "foo",
            social_user_picture_url: "bar",
            social_rich_menu_key: SocialAccounts::RichMenus::CustomerReservations::KEY
          ).count
        }.by(1)
      end
    end
  end
end
