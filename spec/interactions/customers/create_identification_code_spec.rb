require "rails_helper"

RSpec.describe Customers::CreateIdentificationCode do
  let(:user) { customer.user }
  let(:customer) { FactoryBot.create(:customer) }
  let(:phone_number) { Faker::PhoneNumber.phone_number }
  let(:args) do
    {
      user: user,
      customer: customer,
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
        BookingCode.where(customer_id: customer.id).count
      }.by(1)
    end

    context "when Sms::Create failed" do
      it "doesn't create a booking_code" do
        expect(Sms::Create).to receive(:run).and_return(spy(invalid?: true))

        expect {
          outcome
        }.not_to change {
          BookingCode.where(customer_id: customer.id).count
        }
      end
    end
  end
end
