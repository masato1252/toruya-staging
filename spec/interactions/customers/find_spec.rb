# frozen_string_literal: true

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
        customer = FactoryBot.create(
          :customer, user: user, first_name: first_name, last_name: last_name,
          phone_numbers_details: ["type" => "mobile", "value" => phone_number]
        )

        result = outcome.result

        expect(result).to eq({
          found_customer: customer,
          matched_customers: [customer]
        })
      end
    end

    context "when multiple customers matched" do
      context "when no reservations" do
        it "returns the recent reservation's customer" do
          customer1 = FactoryBot.create(
            :customer, user: user, first_name: first_name, last_name: last_name,
            phone_numbers_details: ["type" => "mobile", "value" => phone_number])
          customer2 = FactoryBot.create(
            :customer, user: user, first_name: first_name, last_name: last_name,
            phone_numbers_details: ["type" => "mobile", "value" => phone_number])

          result = outcome.result

          expect(result).to eq({
            found_customer: customer2,
            matched_customers: [customer1, customer2]
          })
        end
      end

      context "when these customers ever had reservations" do
        it "returns the recent reservation's customer" do
          customer1 = FactoryBot.create(
            :customer, user: user, first_name: first_name, last_name: last_name,
            phone_numbers_details: ["type" => "mobile", "value" => phone_number])
          customer2 = FactoryBot.create(
            :customer, user: user, first_name: first_name, last_name: last_name,
            phone_numbers_details: ["type" => "mobile", "value" => phone_number])
          FactoryBot.create(:reservation_customer, customer: customer1)
          FactoryBot.create(:reservation_customer, customer: customer2)

          result = outcome.result

          expect(result).to eq({
            found_customer: customer2,
            matched_customers: [customer1, customer2]
          })
        end
      end

      context "when these customers connected with social customer" do
        it "returns the recent reservation's customer" do
          customer1 = FactoryBot.create(
            :customer, user: user, first_name: first_name, last_name: last_name,
            phone_numbers_details: ["type" => "mobile", "value" => phone_number])
          customer2 = FactoryBot.create(
            :customer, user: user, first_name: first_name, last_name: last_name,
            phone_numbers_details: ["type" => "mobile", "value" => phone_number])
          FactoryBot.create(:social_customer, customer: customer2)

          result = outcome.result

          expect(result).to eq({
            found_customer: customer2,
            matched_customers: [customer1, customer2]
          })
        end
      end
    end
  end
end
