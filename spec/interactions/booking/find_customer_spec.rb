require "rails_helper"

RSpec.describe Booking::FindCustomer do
  let(:booking_page) { FactoryBot.create(:booking_page) }
  let(:user) { booking_page.user }
  let(:last_name) { "foo" }
  let(:first_name) { "bar" }
  let(:phone_number) { Faker::PhoneNumber.phone_number }
  let(:args) do
    {
      booking_page: booking_page,
      last_name: last_name,
      first_name: first_name,
      phone_number: phone_number
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    context "when no customers match" do
      it "returns expected result" do
        FactoryBot.create(:customer, user: user)

        result = outcome.result

        expect(result).to eq(nil)
      end
    end

    context "when only one customer matched" do
      it "returns expected result" do
        customer = FactoryBot.create(:customer, user: user, first_name: first_name, last_name: last_name)
        result = outcome.result

        expect(result).to eq(customer)
      end
    end

    context "when multiple customers matched" do
      context "when there is a customer phone number matched" do
        it "returns the first phone_number matched one" do
          customer1 = FactoryBot.create(:customer, user: user, first_name: first_name, last_name: last_name)
          customer2 = FactoryBot.create(:customer, user: user, first_name: first_name, last_name: last_name)
          query2 = spy(to_a: [customer1, customer2])
          allow(user.customers).to receive(:where).with(phonetic_last_name: last_name, phonetic_first_name: first_name).and_return(query2)
          allow(user.customers).to receive(:where).with(last_name: last_name, first_name: first_name).and_return(spy(or: query2))
          expected_customer = spy(primary_phone: spy(value: phone_number))
          allow(customer1).to receive(:with_google_contact).and_return(expected_customer)
          allow(NotificationMailer).to receive(:duplicate_customers).with(user, [customer1, customer2]).and_return(double(deliver_later: true))

          result = outcome.result

          expect(result).to eq(expected_customer)
          expect(NotificationMailer).to have_received(:duplicate_customers).with(user, [customer1, customer2])
        end
      end

      context "when these customer ever had reservations" do
        it "returns the recent reservation's customer" do
          customer1 = FactoryBot.create(:customer, user: user, first_name: first_name, last_name: last_name)
          customer2 = FactoryBot.create(:customer, user: user, first_name: first_name, last_name: last_name)
          FactoryBot.create(:reservation_customer, customer: customer1)
          FactoryBot.create(:reservation_customer, customer: customer2)

          result = outcome.result

          expect(result).to eq(customer2)
        end
      end

      context "when no matched phone number and no reservations" do
        it "returns the recent created customer" do
          customer1 = FactoryBot.create(:customer, user: user, first_name: first_name, last_name: last_name)
          customer2 = FactoryBot.create(:customer, user: user, first_name: first_name, last_name: last_name)

          result = outcome.result

          expect(result).to eq(customer2)
        end
      end
    end
  end
end
