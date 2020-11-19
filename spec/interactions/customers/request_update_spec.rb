require "rails_helper"

RSpec.describe Customers::RequestUpdate do
  let(:reservation_customer) { FactoryBot.create(:reservation_customer, :with_new_customer_info) }
  let(:args) do
    {
      reservation_customer: reservation_customer
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    it "updates the params value" do
      updated_customer = outcome.result

      expect(updated_customer.last_name).to eq(reservation_customer.customer_info.last_name)
      expect(updated_customer.first_name).to eq(reservation_customer.customer_info.first_name)
      expect(updated_customer.phonetic_last_name).to eq(reservation_customer.customer_info.phonetic_last_name)
      expect(updated_customer.phonetic_first_name).to eq(reservation_customer.customer_info.phonetic_first_name)
      expect(updated_customer.phone_number).to eq(reservation_customer.customer_info.phone_number)
      expect(updated_customer.address_details).to eq(reservation_customer.customer_info.address_details)
      expect(updated_customer.address_details).to eq(reservation_customer.customer_info.address_details)
    end
  end
end
