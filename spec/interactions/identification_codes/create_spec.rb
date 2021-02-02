# frozen_string_literal: true

require "rails_helper"

RSpec.describe IdentificationCodes::Create do
  let(:user) { FactoryBot.create(:user) }
  let(:phone_number) { Faker::PhoneNumber.phone_number }
  let(:args) do
    {
      user: user,
      phone_number: phone_number
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    it "creates a booking_code" do
      expect(Sms::Create).to receive(:run).and_return(spy(invalid?: false))

      expect {
        outcome
      }.to change {
        BookingCode.count
      }.by(1)
    end

    context "when Sms::Create failed" do
      it "doesn't create a booking_code" do
        expect(Sms::Create).to receive(:run).and_return(spy(invalid?: true))

        expect {
          outcome
        }.not_to change {
          BookingCode.count
        }
      end
    end
  end
end
