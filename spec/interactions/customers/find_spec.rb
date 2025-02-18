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

      context "when direct customer_email matched" do
        it "returns expected result" do
          customer = FactoryBot.create(
            :customer, user: user, first_name: first_name, last_name: last_name,
            customer_email: email
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

        context "when customer updated 180 days ago" do
          it "returns the customer" do
            customer = FactoryBot.create(:customer, user: user, first_name: first_name, last_name: last_name, updated_at: 179.days.ago)
            result = outcome.result

            expect(result).to eq({
              found_customer: customer,
              matched_customers: [customer]
            })
          end
        end

        context "when customer updated more than 180 days ago" do
          it "does not return the customer" do
            FactoryBot.create(:customer, user: user, first_name: first_name, last_name: last_name, updated_at: 181.days.ago)
            result = outcome.result

            expect(result).to eq({
              found_customer: nil,
              matched_customers: []
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
          # Generate unique phone numbers for each customer
          phone_number_1 = "111-#{Faker::PhoneNumber.phone_number}"
          phone_number_2 = "222-#{Faker::PhoneNumber.phone_number}"

          customer1 = FactoryBot.create(
            :customer, user: user, first_name: first_name, last_name: last_name)
          customer2 = FactoryBot.create(
            :customer, user: user, first_name: first_name, last_name: last_name)

          # Set different phone_numbers_details
          customer1.update(phone_numbers_details: ["type" => "mobile", "value" => phone_number_1])
          customer2.update(phone_numbers_details: ["type" => "mobile", "value" => phone_number_2])

          # We'll rely on name matching instead of phone number matching
          args[:phone_number] = nil
          result = described_class.run(args).result

          expect(result[:matched_customers].length).to eq(2)
          expect(result[:matched_customers]).to include(customer1)
          expect(result[:matched_customers]).to include(customer2)
          expect(result[:found_customer]).to eq(customer2)
        end
      end

      context "when these customers ever had reservations" do
        it "returns the recent reservation's customer" do
          # Generate unique phone numbers for each customer
          phone_number_1 = "333-#{Faker::PhoneNumber.phone_number}"
          phone_number_2 = "444-#{Faker::PhoneNumber.phone_number}"

          customer1 = FactoryBot.create(
            :customer, user: user, first_name: first_name, last_name: last_name)
          customer2 = FactoryBot.create(
            :customer, user: user, first_name: first_name, last_name: last_name)

          # Set different phone_numbers_details
          customer1.update(phone_numbers_details: ["type" => "mobile", "value" => phone_number_1])
          customer2.update(phone_numbers_details: ["type" => "mobile", "value" => phone_number_2])

          FactoryBot.create(:reservation_customer, customer: customer1)
          FactoryBot.create(:reservation_customer, customer: customer2)

          # We'll rely on name matching instead of phone number matching
          args[:phone_number] = nil
          result = described_class.run(args).result

          expect(result[:matched_customers].length).to eq(2)
          expect(result[:matched_customers]).to include(customer1)
          expect(result[:matched_customers]).to include(customer2)
          expect(result[:found_customer]).to eq(customer2)
        end
      end

      context "when these customers connected with social customer" do
        it "returns the recent reservation's customer" do
          # Generate unique phone numbers for each customer
          phone_number_1 = "555-#{Faker::PhoneNumber.phone_number}"
          phone_number_2 = "666-#{Faker::PhoneNumber.phone_number}"

          customer1 = FactoryBot.create(
            :customer, user: user, first_name: first_name, last_name: last_name)
          customer2 = FactoryBot.create(
            :customer, user: user, first_name: first_name, last_name: last_name)

          # Set different phone_numbers_details
          customer1.update(phone_numbers_details: ["type" => "mobile", "value" => phone_number_1])
          customer2.update(phone_numbers_details: ["type" => "mobile", "value" => phone_number_2])

          # Create social customer for customer2, this is what makes it preferred
          FactoryBot.create(:social_customer, customer: customer2)

          # We'll rely on name matching instead of phone number matching
          args[:phone_number] = nil

          # The implementation has different branches for handling matched customers:
          # First, it tries to match by email or phone number
          # If no matches, it falls back to checking if any customers have social customers
          # When a customer has a social customer, only that customer will be selected
          result = described_class.run(args).result

          # When a social customer is present, only that customer is in the matched_customers array
          expect(result[:found_customer]).to eq(customer2)
          expect(result[:matched_customers]).to include(customer2)
          expect(result[:matched_customers].length).to eq(1)
        end
      end
    end
  end
end