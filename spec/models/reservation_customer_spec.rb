require 'rails_helper'

RSpec.describe ReservationCustomer, type: :model do
  let(:reservation_customer) { FactoryBot.create(:reservation_customer, :with_new_customer_info) }

  it "only shows the differences" do
    expect(reservation_customer.customer_data_changes).to eq([
      "last_name",
      "first_name",
      "phonetic_last_name",
      "phonetic_first_name",
      "phone_number",
      "email",
      "zip_code",
      "region",
      "city",
      "street1",
      "street2"
    ])
  end

  context "some info are the same" do
    it "only shows the differences" do
      customer = reservation_customer.customer
      allow(customer).to receive(:with_google_contact).and_return(spy(
        first_name: "first_name",
        primary_phone: double(value: "phone_number"),
        primary_email: double(value: double(address: "email")),
        primary_address: double(value: spy(
          zip_code: "zip_code",
          city: "city",
          street: "street"
        ))
      ))

      expect(reservation_customer.customer_data_changes).to eq([
        "last_name",
        "phonetic_last_name",
        "phonetic_first_name",
        "region",
        "street1",
        "street2"
      ])
    end
  end
end
