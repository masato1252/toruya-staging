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
        "text"=>"??"
      }
    }
  end
  let(:social_customer) { FactoryBot.create(:social_customer) }

  let(:args) do
    {
      event: event,
      social_customer: social_customer
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    context "when event exists" do
      it "creates a social messages" do
        expect(Lines::FeaturesButton).to receive(:run).with(social_customer: social_customer).and_return(double(invalid?: false, result: nil))

        expect {
          outcome
        }.to change {
          SocialMessage.where(social_customer: social_customer, message_type: SocialMessage.message_types[:customer]).count
        }.by(1)
      end
    end

    context "when social_customer is one_on_one" do
      let(:message_type) { "image" }
      let(:social_customer) { FactoryBot.create(:social_customer, :one_on_one) }

      it "doesn't call Lines::FeaturesButton" do
        expect(Lines::FeaturesButton).not_to receive(:run)
        expect(LineClient).to receive(:send)

        outcome
      end
    end
  end
end
