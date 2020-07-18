require "rails_helper"
require "random_code"

RSpec.describe Customers::VerifyIdentificationCode do
  let(:social_customer) { FactoryBot.create(:social_customer) }
  let(:uuid) { SecureRandom.uuid }
  let(:code) { RandomCode.generate(6) }
  let(:args) do
    {
      social_customer: social_customer,
      uuid: uuid,
      code: code
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    context "when there is booking code matched" do
      let!(:booking_code) { FactoryBot.create(:booking_code, customer_id: FactoryBot.create(:customer, user: social_customer.user).id) }
      let(:uuid) { booking_code.uuid }
      let(:code) { booking_code.code }

      it "returns the matched booking code object and connect with social_customer" do
        expect(LineClient).to receive(:send).with(social_customer, I18n.t("line.bot.connected_successfuly"))
        expect(Lines::Features).to receive(:run).with(social_customer: social_customer)

        expect(outcome.result).to eq(booking_code)
        expect(social_customer.customer_id).to eq(booking_code.customer_id)
      end
    end
  end
end
