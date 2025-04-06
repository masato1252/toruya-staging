# frozen_string_literal: true

require "rails_helper"

RSpec.describe SocialMessages::Recent do
  let(:social_customer) { FactoryBot.create(:social_customer) }
  let(:customer) { social_customer.customer }
  let(:user) { customer.user }
  let!(:social_message) do
    FactoryBot.create(:social_message,
      social_customer: social_customer,
      customer: customer,
      user: user,
      sent_at: 1.day.ago,
      raw_content: "test message 1"
    )
  end
  let(:args) do
    {
      customer: customer
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    it "returns expected messages" do
      expect(UserBotLines::Actions::SwitchRichMenu).to receive(:run).with(social_user: customer.user.social_user)
      outcome

      expect(social_message.reload.readed_at).not_to be_nil
      expect(outcome.result).to eq(
        messages: [MessageSerializer.new(social_message).attributes_hash],
        has_more_messages: false
      )
    end

    context "when this customer got multiple social customers(line account)" do
      let(:social_customer2) { FactoryBot.create(:social_customer, customer: customer, user: user) }
      let!(:social_message2) do
        FactoryBot.create(:social_message,
          social_customer: social_customer2,
          customer: customer,
          user: user,
          sent_at: 2.days.ago,
          raw_content: "test message 2"
        )
      end

      it "returns expected messages from multiple accounts" do
        expect(UserBotLines::Actions::SwitchRichMenu).to receive(:run).with(social_user: customer.user.social_user)
        outcome

        expect(social_message.reload.readed_at).not_to be_nil
        expect(social_message2.reload.readed_at).not_to be_nil
        expect(outcome.result).to eq(
          messages: [MessageSerializer.new(social_message2).attributes_hash, MessageSerializer.new(social_message).attributes_hash],
          has_more_messages: false
        )
      end
    end

    context "when customer has messages from different channels" do
      let!(:email_message) do
        FactoryBot.create(:social_message,
          social_customer: nil,
          social_account: nil,
          customer: customer,
          user: user,
          sent_at: 3.days.ago,
          raw_content: "test email message",
          channel: "email",
          message_type: "bot"
        )
      end

      let!(:sms_message) do
        FactoryBot.create(:social_message,
          social_customer: nil,
          social_account: nil,
          customer: customer,
          user: user,
          sent_at: 4.days.ago,
          raw_content: "test sms message",
          channel: "sms",
          message_type: "bot"
        )
      end

      it "returns messages from all channels in correct order" do
        expect(UserBotLines::Actions::SwitchRichMenu).to receive(:run).with(social_user: customer.user.social_user)
        outcome

        expect(social_message.reload.readed_at).not_to be_nil
        expect(email_message.reload.readed_at).not_to be_nil
        expect(sms_message.reload.readed_at).not_to be_nil

        expect(outcome.result).to eq(
          messages: [
            MessageSerializer.new(sms_message).attributes_hash,
            MessageSerializer.new(email_message).attributes_hash,
            MessageSerializer.new(social_message).attributes_hash
          ],
          has_more_messages: false
        )
      end
    end
  end
end
