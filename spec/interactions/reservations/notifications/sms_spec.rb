# frozen_string_literal: true

require "rails_helper"

RSpec.describe Reservations::Notifications::Sms do
  let(:phone_number) { Faker::PhoneNumber.phone_number }
  let(:user) { customer.user }
  let(:customer) { FactoryBot.create(:customer) }
  let(:reservation) { FactoryBot.create(:reservation, shop: FactoryBot.create(:shop, user: user)) }
  let(:message) { "foo" }

  let(:args) do
    {
      phone_number: phone_number,
      customer: customer,
      reservation: reservation,
      message: message
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    it "calls Sms::Create" do
      expect(Sms::Create).to receive(:run).and_return(spy(invalid?: false))

      outcome
    end
  end
end
