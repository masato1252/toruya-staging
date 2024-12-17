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
  let(:user) { social_customer.user }
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

      context "when keyword is from rich menu" do
        let!(:social_rich_menu) do
          FactoryBot.create(:social_rich_menu,
            social_account: social_customer.social_account,
            social_name: social_customer.social_rich_menu_key,
            body: {
              "areas" => [
                {
                  "bounds" => {"x" => 0, "y" => 0, "width" => 100, "height" => 100},
                  "action" => {"type" => "message", "text" => text}
                }
              ]
            }
          )
        end

        context "when not using line official account" do
          it "tracks function access" do
            expect(FunctionAccess).to receive(:track_access).with(
              content: text,
              source_type: "SocialRichMenu", 
              source_id: social_customer.social_rich_menu_key,
              action_type: "keyword",
              label: text
            )
            outcome
          end
        end

        context "when using line official account" do
          before do
            allow(social_customer.social_account).to receive(:using_line_official_account?).and_return(true)
          end

          it "does not track function access" do
            expect(FunctionAccess).not_to receive(:track_access)
            outcome
          end
        end
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

    context "when event text does NOT match keyword" do
      let(:text) { "Hello" }

      context "when line customer does NOT have customer" do
        let(:social_customer) { FactoryBot.create(:social_customer, customer: nil) }
        before { user.user_setting.update!(line_contact_customer_name_required: false) }

        context "when line_contact_customer_name_required is false" do
          it "creates a customer automatically" do
            expect {
              outcome
            }.to change {
              user.customers.count
            }.by(1)
          end
        end

        context "when line_contact_customer_name_required is true" do
          before { user.user_setting.update!(line_contact_customer_name_required: true) }

          it "does NOT creates a customer automatically" do
            expect {
              outcome
            }.not_to change {
              user.customers.count
            }
          end
        end
      end
    end
  end
end
