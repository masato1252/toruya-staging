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
      expect(LineClient).to have_received(:send).with(social_customer, I18n.t("line.bot.connected_successfuly"))
    end

    context "when customer was connected with other social_customer" do
      let!(:other_social_cusomter) { FactoryBot.create(:social_customer, customer: customer, user_id: social_customer.user_id) }

      it "was invalid" do
        expect(outcome).to be_invalid
      end
    end
  end
end
