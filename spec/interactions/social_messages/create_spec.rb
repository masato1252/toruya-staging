# frozen_string_literal: true

require "rails_helper"

RSpec.describe SocialMessages::Create, :with_line do
  let!(:social_customer) { FactoryBot.create(:social_customer) }
  let(:user) { social_customer.user }
  let(:readed) { false }
  let(:message_type) { SocialMessage.message_types[:customer] }
  let(:staff) {}
  let(:schedule_at) {}
  let(:send_line) { true }
  let(:args) do
    {
      social_customer: social_customer,
      content: "foo",
      readed: readed,
      message_type: message_type,
      schedule_at: schedule_at,
      staff: staff,
      send_line: send_line
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    context "when message is from customer" do
      it "returns expected messages" do
        expect(::RichMenus::BusinessSwitchRichMenu).to receive(:run).with(
          owner: social_customer.user,
          rich_menu_key: UserBotLines::RichMenus::DashboardWithNotifications::KEY
        )
        outcome

        social_message = social_customer.social_messages.last

        expect(user.reload.customer_latest_activity_at).to be_present
        expect(social_message.readed_at).to be_nil
        expect(social_message.sent_at).to be_present
        expect(social_message.schedule_at).to be_nil
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
        expect(social_message.schedule_at).to be_nil
        expect(social_message.sent_at).to be_present
      end

      context "when message is scheduled" do
        let(:schedule_at) { Time.current }

        it "returns expected messages" do
          outcome

          social_message = social_customer.social_messages.last

          expect(social_message.schedule_at).to be_present
          expect(social_message.sent_at).to be_nil
        end
      end

      context "when message is from send_line false" do
        let(:send_line) { false }

        it "returns expected messages" do
          outcome

          social_message = social_customer.social_messages.last

          expect(social_message.schedule_at).to be_nil
          expect(social_message.sent_at).to be_present
        end
      end
    end
  end
end
