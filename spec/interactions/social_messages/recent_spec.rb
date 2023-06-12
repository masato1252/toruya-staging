# frozen_string_literal: true

require "rails_helper"

RSpec.describe SocialMessages::Recent do
  let!(:social_message) { FactoryBot.create(:social_message) }
  let(:customer) { social_message.social_customer.customer }
  let(:args) do
    {
      customer: customer
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    it "returns expected messages" do
      expect(UserBotLines::Actions::SwitchRichMenu).to receive(:run).with(
        social_user: customer.user.social_user,
        rich_menu_key: UserBotLines::RichMenus::Dashboard::KEY
      )
      outcome

      expect(social_message.reload.readed_at).not_to be_nil
      expect(outcome.result).to eq(
        messages: [MessageSerializer.new(social_message).attributes_hash],
        has_more_messages: false
      )
    end

    context "when this customer got multiple social customers(line account)" do
      let!(:social_message2) { FactoryBot.create(:social_message) }
      before { social_message2.social_customer.update_columns(customer_id: customer.id) }

      it "returns expected messages from multiple accounts" do
        expect(UserBotLines::Actions::SwitchRichMenu).to receive(:run).with(
          social_user: customer.user.social_user,
          rich_menu_key: UserBotLines::RichMenus::Dashboard::KEY
        )
        outcome

        expect(social_message.reload.readed_at).not_to be_nil
        expect(social_message2.reload.readed_at).not_to be_nil
        expect(outcome.result).to eq(
          messages: [MessageSerializer.new(social_message).attributes_hash, MessageSerializer.new(social_message2).attributes_hash],
          has_more_messages: false
        )
      end
    end
  end
end
