# frozen_string_literal: true

require "rails_helper"

RSpec.describe Customers::Find do
  let(:user) { FactoryBot.create(:user) }
  let(:last_name) { "foo" }
  let(:first_name) { "bar" }
  let(:phone_number) { Faker::PhoneNumber.phone_number }
  let(:email) { "example@email.com" }
  let(:args) do
    {
      user: user,
      last_name: last_name,
      first_name: first_name,
      phone_number: phone_number,
      email: email
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
      context "when phone number matched" do
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

      context "when email matched" do
        it "returns expected result" do
          customer = FactoryBot.create(
            :customer, user: user, first_name: first_name, last_name: last_name,
            emails_details: ["type" => "mobile", "value" => email]
          )

          result = outcome.result

          expect(result).to eq({
            found_customer: customer,
            matched_customers: [customer]
          })
        end
      end

      context "when only customer name matched (phone number is not matched)" do
        context "when customer updated 30 days ago" do
          it "returns the customer" do
            customer = FactoryBot.create(:customer, user: user, first_name: first_name, last_name: last_name, updated_at: 29.days.ago)
            result = outcome.result

            expect(result).to eq({
              found_customer: customer,
              matched_customers: [customer]
            })
          end
        end
      end

      context "when customer got social customer" do
        it "returns the customer" do
          customer = FactoryBot.create(:customer, user: user, first_name: first_name, last_name: last_name, social_customer: FactoryBot.create(:social_customer))
          result = outcome.result

          expect(result).to eq({
            found_customer: customer,
            matched_customers: [customer]
          })
        end
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