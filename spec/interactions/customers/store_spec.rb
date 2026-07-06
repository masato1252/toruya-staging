# frozen_string_literal: true

require "rails_helper"

RSpec.describe Customers::Store do
  let(:user) { create(:user) }
  let(:current_user) { user }
  let(:contact_group) { create(:contact_group, user: user) }

  describe "#execute" do
    context "when creating a new customer" do
      let(:params) do
        {
          last_name: "Test",
          first_name: "User",
          contact_group_id: contact_group.id.to_s,
          emails_details: [
            { "type" => "mobile", "value" => "test＠example.com" }
          ]
        }
      end

      it "normalizes full-width @ to half-width @ in email addresses" do
        outcome = described_class.run(
          user: user,
          current_user: current_user,
          params: params
        )

        expect(outcome).to be_valid
        expect(outcome.result.emails_details.first["value"]).to eq("test@example.com")
      end
    end

    context "when updating an existing customer" do
      let!(:customer) { create(:customer, user: user) }
      let(:params) do
        {
          id: customer.id.to_s,
          contact_group_id: contact_group.id.to_s,
          emails_details: [
            { "type" => "mobile", "value" => "update＠example.com" }
          ]
        }
      end

      it "normalizes full-width @ to half-width @ in email addresses" do
        outcome = described_class.run(
          user: user,
          current_user: current_user,
          params: params
        )

        expect(outcome).to be_valid
        expect(outcome.result.emails_details.first["value"]).to eq("update@example.com")
      end
    end

    context "when partially updating an existing customer" do
      let!(:customer) do
        create(
          :customer,
          user: user,
          custom_id: "TYS000004",
          birthday: Date.new(1971, 8, 20),
          last_name: "森本",
          first_name: "圭子"
        )
      end
      let(:params) do
        {
          id: customer.id.to_s,
          last_name: "森本",
          first_name: "圭子",
          phone_numbers_details: [{ "type" => "mobile", "value" => "09012345678" }],
          emails_details: [{ "type" => "mobile", "value" => "test@example.com" }]
        }
      end

      it "preserves custom_id and birthday" do
        outcome = described_class.run(
          user: user,
          current_user: current_user,
          params: params
        )

        expect(outcome).to be_valid
        customer.reload
        expect(customer.custom_id).to eq("TYS000004")
        expect(customer.birthday).to eq(Date.new(1971, 8, 20))
        expect(customer.phone_numbers_details.first["value"]).to eq("09012345678")
      end
    end

    context "when email contains multiple full-width @ characters" do
      let(:params) do
        {
          last_name: "Test",
          first_name: "User",
          contact_group_id: contact_group.id.to_s,
          emails_details: [
            { "type" => "mobile", "value" => "test＠sub＠example.com" }
          ]
        }
      end

      it "normalizes all full-width @ to half-width @" do
        outcome = described_class.run(
          user: user,
          current_user: current_user,
          params: params
        )

        expect(outcome).to be_valid
        expect(outcome.result.emails_details.first["value"]).to eq("test@sub@example.com")
      end
    end

    context "when emails_details array is empty" do
      let(:params) do
        {
          last_name: "Test",
          first_name: "User",
          contact_group_id: contact_group.id.to_s,
          emails_details: []
        }
      end

      it "creates customer without error" do
        outcome = described_class.run(
          user: user,
          current_user: current_user,
          params: params
        )

        expect(outcome).to be_valid
        expect(outcome.result.emails_details).to be_empty
      end
    end
  end
end
