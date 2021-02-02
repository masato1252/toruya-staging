# frozen_string_literal: true

require "rails_helper"

RSpec.describe SocialMessages::Create do
  let!(:social_customer) { FactoryBot.create(:social_customer) }
  let(:readed) { false }
  let(:message_type) { SocialMessage.message_types[:customer] }
  let(:staff) {}
  let(:args) do
    {
      social_customer: social_customer,
      content: "foo",
      readed: readed,
      message_type: message_type,
      staff: staff
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    context "when message is from customer" do
      it "returns expected messages" do
        expect(UserBotLines::Actions::SwitchRichMenu).to receive(:run).with(
          social_user: social_customer.user.social_user,
          rich_menu_key: UserBotLines::RichMenus::DashboardWithNotifications::KEY
        )
        outcome

        social_message = social_customer.social_messages.last

        expect(social_message.readed_at).to be_nil
        expect(social_message.message_type).to eq("customer")
      end
    end

    context "when message is from staff" do
      let(:readed) { true }
      let(:message_type) { SocialMessage.message_types[:staff] }
      let(:staff) { FactoryBot.create(:staff) }

      it "returns expected messages" do
        expect(LineClient).to receive(:send).with(social_customer, "foo")
        outcome

        social_message = social_customer.social_messages.last

        expect(social_message.readed_at).not_to be_nil
        expect(social_message.message_type).to eq("staff")
        expect(social_message.staff_id).to eq(staff.id)
      end
    end
  end
end
