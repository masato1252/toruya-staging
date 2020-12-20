require "rails_helper"

RSpec.describe Lines::MessageEvent do
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
        "text"=> text
      }
    }
  end
  let(:social_customer) { FactoryBot.create(:social_customer) }
  let(:text) { I18n.t("line.bot.keywords").values.sample }

  let(:args) do
    {
      event: event,
      social_customer: social_customer
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    context "when event text match keyowrd" do
      it "creates a social messages" do
        allow(LineClient).to receive(:send)

        expect {
          outcome
        }.to change {
          SocialMessage.where(social_customer: social_customer, message_type: SocialMessage.message_types[:customer_reply_bot]).count
        }.by(1)
      end
    end
  end
end
