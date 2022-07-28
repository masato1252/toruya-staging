# frozen_string_literal: true

require "rails_helper"

RSpec.describe Lines::MessageEvent, :with_line do
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
    context "when event text match keyword" do
      it "creates a social messages" do
        expect {
          outcome
        }.to change {
          SocialMessage.where(social_customer: social_customer, message_type: SocialMessage.message_types[:customer_reply_bot]).count
        }.by(1)
      end
    end

    context "when keyword match services" do
      let(:last_relation_id) { "123" }
      let(:text) { "#{I18n.t("common.more")} - #{I18n.t("line.bot.keywords.services")} #{last_relation_id}" }

      it "extracts out the last_relation_id" do
        expect(Lines::Actions::ActiveOnlineServices).to receive(:run).with(social_customer: social_customer, last_relation_id: last_relation_id, bundler_service_id: nil)
        outcome
      end

      context 'when match bundler service pattern' do
        let(:last_relation_id) { "123" }
        let(:bundler_service_id) { "456" }
        let(:text) { "#{I18n.t("common.more")} - #{I18n.t("line.bot.keywords.services")} ~456~ 123" }

        it "extracts out the bundler_service_id" do
          expect(Lines::Actions::ActiveOnlineServices).to receive(:run).with(social_customer: social_customer, last_relation_id: last_relation_id, bundler_service_id: bundler_service_id)
          outcome
        end
      end
    end
  end
end
