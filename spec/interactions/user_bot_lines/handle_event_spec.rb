# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserBotLines::HandleEvent do
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

  let(:args) do
    {
      event: event,
    }
  end
  let(:outcome) { described_class.run(args) }

  # describe "#execute" do
  #   context "when message_type is message" do
  #     it "creates expected social_user and executes expected event" do
  #       response = Net::HTTPOK.new(1.0, "200", "OK")
  #       expect(LineClient).to receive(:profile).and_return(response)
  #       expect(response).to receive(:body) { {displayName: "foo", pictureUrl: "bar"}.to_json }
  #       expect(UserBotLines::MessageEvent).to receive(:run!)

  #       expect {
  #         outcome
  #         perform_enqueued_jobs
  #       }.to change {
  #         SocialUser.where(
  #           social_user_name: "foo",
  #           social_user_picture_url: "bar",
  #           social_rich_menu_key: UserBotLines::RichMenus::Guest::KEY
  #         ).count
  #       }.by(1)
  #     end
  #   end
  # end
end
