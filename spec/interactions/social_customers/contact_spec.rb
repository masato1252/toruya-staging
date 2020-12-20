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
        expect(LineClient).to receive(:send).with(social_customer, I18n.t("contact_page.message_sent.line_content"))
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
        expect(LineClient).to receive(:send).with(social_customer, I18n.t("contact_page.message_sent.line_content"))
        expect {
          outcome
        }.to change {
          SocialMessage.where(social_customer: social_customer, readed_at: nil, message_type: SocialMessage.message_types[:customer]).count
        }.by(1).and change {
          user.customers.count
        }.by(1)

        customer = user.customers.last

        expect(social_customer.customer).to eq(customer)
        expect(customer.last_name).to eq("bar")
        expect(customer.first_name).to eq("qaz")
        expect(customer.first_name).to eq("qaz")
        expect(customer.phonetic_last_name).to be_nil
        expect(customer.phonetic_first_name).to be_nil
        expect(customer.emails_details).to be_empty
        expect(customer.phone_numbers_details).to be_empty
        expect(customer.address_details).to be_empty
      end
    end
  end
end
