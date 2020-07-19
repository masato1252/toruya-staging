require "rails_helper"

RSpec.describe Customers::Find do
  let(:user) { FactoryBot.create(:user) }
  let(:last_name) { "foo" }
  let(:first_name) { "bar" }
  let(:phone_number) { Faker::PhoneNumber.phone_number }
  let(:args) do
    {
      user: user,
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

        expect(result).to eq({
          found_customer: nil,
          matched_customers: []
        })
      end
    end

    context "when only one customer matched" do
      it "returns expected result" do
        customer = FactoryBot.create(:customer, user: user, first_name: first_name, last_name: last_name)
        query = spy(to_a: [customer])
        expected_customer = spy(phone_numbers: [spy(value: phone_number)])
        allow(user.customers).to receive(:where).with(phonetic_last_name: last_name, phonetic_first_name: first_name).and_return(query)
        allow(user.customers).to receive(:where).with(last_name: last_name, first_name: first_name).and_return(spy(or: query))
        allow(customer).to receive(:with_google_contact).and_return(expected_customer)

        result = outcome.result

        expect(result).to eq({
          found_customer: expected_customer,
          matched_customers: [customer]
        })
      end
    end

    context "when multiple customers matched" do
      context "when no reservations" do
        it "returns the recent reservation's customer" do
          customer1 = FactoryBot.create(:customer, user: user, first_name: first_name, last_name: last_name)
          customer2 = FactoryBot.create(:customer, user: user, first_name: first_name, last_name: last_name)
          query = spy(to_a: [customer1, customer2])
          expected_customer1 = spy(phone_numbers: [spy(value: phone_number)])
          expected_customer2 = spy(phone_numbers: [spy(value: phone_number)])
          allow(user.customers).to receive(:where).with(phonetic_last_name: last_name, phonetic_first_name: first_name).and_return(query)
          allow(user.customers).to receive(:where).with(last_name: last_name, first_name: first_name).and_return(spy(or: query))
          allow(customer1).to receive(:with_google_contact).and_return(expected_customer1)
          allow(customer2).to receive(:with_google_contact).and_return(expected_customer2)

          result = outcome.result

          expect(result).to eq({
            found_customer: expected_customer2,
            matched_customers: [customer1, customer2]
          })
        end
      end

      context "when these customer ever had reservations" do
        it "returns the recent reservation's customer" do
          customer1 = FactoryBot.create(:customer, user: user, first_name: first_name, last_name: last_name)
          customer2 = FactoryBot.create(:customer, user: user, first_name: first_name, last_name: last_name)
          query = spy(to_a: [customer1, customer2])
          expected_customer1 = spy(phone_numbers: [spy(value: phone_number)])
          expected_customer2 = spy(phone_numbers: [spy(value: phone_number)])
          allow(user.customers).to receive(:where).with(phonetic_last_name: last_name, phonetic_first_name: first_name).and_return(query)
          allow(user.customers).to receive(:where).with(last_name: last_name, first_name: first_name).and_return(spy(or: query))
          allow(customer1).to receive(:with_google_contact).and_return(expected_customer1)
          allow(customer2).to receive(:with_google_contact).and_return(expected_customer2)
          FactoryBot.create(:reservation_customer, customer: customer1)
          FactoryBot.create(:reservation_customer, customer: customer2)

          result = outcome.result

          expect(result).to eq({
            found_customer: expected_customer2,
            matched_customers: [customer1, customer2]
          })
        end
      end
    end
  end
end
