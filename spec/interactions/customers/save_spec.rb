# frozen_string_literal: true

require "rails_helper"

RSpec.describe Customers::Save do
  let(:user) { FactoryBot.create(:user, with_google_user: true) }
  let(:customer) { FactoryBot.create(:customer, user: user, contact_group: contact_group) }
  let(:contact_group) { FactoryBot.create(:contact_group, user: user) }
  let(:contact_group2) { FactoryBot.create(:contact_group, user: user) }
  let(:rank) { user.ranks.first }
  let(:params) do
    {
      :id => customer.id,
      :contact_group_id => contact_group2.id,
      :rank_id => rank.id,
      :last_name =>"劉",
      :first_name =>"治子",
      :phonetic_last_name =>"りゅう",
      :phonetic_first_name =>"はるこ",
      :primary_phone =>"mobile#{described_class::DELIMITER}08036238534",
      :primary_email =>"home#{described_class::DELIMITER}taiwanhimawari@gmail.com",
      :primary_address => {
        type: "home",
        postcode1: "123",
        postcode2: "456",
        region: "foo",
        city: "bar",
        street1: "street1",
        street2: "street2"
      },
      :other_addresses =>
      "[{\"type\":\"work\",\"value\":{\"formatted_address\":\"台灣桃園市哈哈街123號4樓之5\",\"street\":\"哈哈街123號4樓之5\",\"region\":\"桃園市\",\"country\":\"台灣\"}}]",
      :phone_numbers => [
        {"type"=>"mobile", "value"=>"08036238534"},
        {"type"=>"home", "value"=>"0524095796"},
        {"type"=>"work", "value"=>"0524002529"}
      ],
      :emails => [
        {"type"=>"home", "value"=>"taiwanhimawari@gmail.com"},
        {"type"=>"unknown", "value"=>"studioha3@dreamhint.com"},
        {"type"=>"work", "value"=>"haruko_liu@dreamhint.com"}
      ],
      :dob => { year: "1950", month: "11", day: "20" }
    }
  end

  xdescribe "#execute" do
    before do
      google_user = spy(create_contact: spy)
      allow(GoogleContactsApi::User).to receive(:new).and_return(google_user)
    end

    it "updates the params value" do
      outcome = Customers::Save.run(user: user, current_user: user, params: params)
      updated_customer = outcome.result
      expect(updated_customer).to eq(customer.reload)
      expect(updated_customer.birthday).to eq(Date.new(1950, 11, 20))
      expect(updated_customer.address).to eq("foo bar")
    end
  end
end
