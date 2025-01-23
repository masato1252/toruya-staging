# frozen_string_literal: true

require "rails_helper"

RSpec.describe SocialCustomers::Contact do
  let(:social_customer) { FactoryBot.create(:social_customer) }
  let(:user) { social_customer.user }
  let(:args) do
    {
      social_customer: social_customer,
      content: "foo"
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    context "when social_customer connected with customer" do
      it "creates a message" do
        expect {
          outcome
        }.to change {
          SocialMessage.where(social_customer: social_customer, readed_at: nil, message_type: SocialMessage.message_types[:customer]).count
        }.by(1).and change {
          user.customers.count
        }.by(0)
      end
    end

    context "when social_customer doesn't connected with customer" do
      let(:social_customer) { FactoryBot.create(:social_customer, customer: nil) }
      let(:args) do
        {
          social_customer: social_customer,
          content: "foo",
          last_name: "bar",
          first_name: "qaz"
        }
      end

      it "creates a message and customer" do
        expect {
          outcome
        }.to change {
          SocialMessage.where(social_customer: social_customer, readed_at: nil, message_type: SocialMessage.message_types[:customer]).count
        }.by(1).and change {
          user.customers.count
        }.by(1)

        customer = user.customers.last

        expect(social_customer.customer).to eq(customer)
        expect(customer).to have_attributes(
          last_name: "bar",
          first_name: "qaz",
          phonetic_last_name: nil,
          phonetic_first_name: nil,
          emails_details: [],
          phone_numbers_details: [],
          address_details: {}
        )
      end
    end
  end
end
