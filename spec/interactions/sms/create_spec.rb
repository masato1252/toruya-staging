# frozen_string_literal: true

require "rails_helper"
require "sms_client"

RSpec.describe Sms::Create do
  let(:user) { FactoryBot.create(:user) }
  let(:phone_number) { Faker::PhoneNumber.phone_number }
  let(:message) { "foo" }

  let(:args) do
    {
      user: user,
      phone_number: phone_number,
      message: message
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    it "calls SmsClient and creates Notification" do
      expect(SmsClient).to receive(:send).with(phone_number, message, user.locale)

      expect {
        outcome
      }.to change {
        Notification.where(user: user, phone_number: phone_number, content: message).count
      }.by(1)
    end
  end
end
