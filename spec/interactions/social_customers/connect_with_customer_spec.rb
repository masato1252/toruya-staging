# frozen_string_literal: true

require "rails_helper"

RSpec.describe SocialCustomers::ConnectWithCustomer do
  let(:social_customer) { FactoryBot.create(:social_customer) }
  let(:customer) { social_customer.customer }
  let(:args) do
    {
      social_customer: social_customer,
      customer: customer
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    it "connects social_customer with customer" do
      allow(LineClient).to receive(:send)

      outcome

      expect(social_customer.customer_id).to eq(customer.id)
      expect(LineClient).to have_received(:send).with(social_customer, I18n.t("line.bot.connected_successfully"))
    end

    context "when customer was connected with other social_customer" do
      let!(:other_social_customer) { FactoryBot.create(:social_customer, customer: customer, user_id: social_customer.user_id) }

      it "connects latest social_customer with customer" do
        allow(LineClient).to receive(:send)

        outcome

        expect(customer.social_customer).to eq(social_customer)
        expect(other_social_customer.reload.customer).to be_nil
      end
    end
  end
end
