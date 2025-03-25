# frozen_string_literal: true

require "rails_helper"

RSpec.describe Profiles::UpdateAttribute do
  let(:user) { FactoryBot.create(:user) }
  let(:profile) { FactoryBot.create(:profile, user: user) }
  let(:shop) { FactoryBot.create(:shop, user: user) }

  # Ensure the shop is properly associated with the user
  before do
    # Make sure the user has this shop as their first shop
    user.shops << shop unless user.shops.include?(shop)
  end

  describe "#execute" do
    context "when updating company_name" do
      let(:new_company_name) { "New Company Name" }
      let(:outcome) do
        described_class.run(
          profile: profile,
          update_attribute: "company_name",
          attrs: { company_name: new_company_name }
        )
      end

      it "updates the profile company_name" do
        outcome
        expect(profile.reload.company_name).to eq(new_company_name)
      end

      it "updates the shop name and short_name" do
        outcome
        expect(shop.reload.read_attribute(:name)).to eq(new_company_name)
        expect(shop.reload.read_attribute(:short_name)).to eq(new_company_name)
      end
    end

    context "when updating company_phone_number" do
      let(:new_phone_number) { "9876543210" }
      let(:outcome) do
        described_class.run(
          profile: profile,
          update_attribute: "company_phone_number",
          attrs: { company_phone_number: new_phone_number }
        )
      end

      it "updates the profile company_phone_number" do
        outcome
        expect(profile.reload.company_phone_number).to eq(new_phone_number)
      end

      it "updates the shop phone_number" do
        outcome
        expect(shop.reload.phone_number).to eq(new_phone_number)
      end
    end

    context "when updating company_email" do
      let(:new_email) { "new_email@example.com" }
      let(:outcome) do
        described_class.run(
          profile: profile,
          update_attribute: "company_email",
          attrs: { company_email: new_email }
        )
      end

      it "updates the profile company_email" do
        outcome
        expect(profile.reload.company_email).to eq(new_email)
      end

      it "updates the shop email" do
        outcome
        expect(shop.reload.email).to eq(new_email)
      end
    end

    context "when updating website" do
      let(:new_website) { "https://newwebsite.com" }
      let(:outcome) do
        described_class.run(
          profile: profile,
          update_attribute: "website",
          attrs: { website: new_website }
        )
      end

      it "updates the profile website" do
        outcome
        expect(profile.reload.website).to eq(new_website)
      end

      it "updates the shop website" do
        outcome
        expect(shop.reload.website).to eq(new_website)
      end
    end

    context "when updating company_address_details" do
      let(:zip_code) { "123-4567" }
      let(:region) { "Tokyo" }
      let(:city) { "Shinjuku" }
      let(:street1) { "1-1" }
      let(:street2) { "Building" }

      let(:address_details) do
        {
          zip_code: zip_code,
          region: region,
          city: city,
          street1: street1,
          street2: street2
        }
      end

      let(:pure_address) { "#{region}#{city}#{street1}#{street2}" }

      # Create a mock address with consistent behavior
      let(:address) do
        address = instance_double(Address)
        allow(address).to receive(:invalid?).and_return(false)
        allow(address).to receive(:pure_address).and_return(pure_address)
        allow(address).to receive(:zip_code).and_return(zip_code)
        allow(address).to receive(:as_json).and_return(address_details.stringify_keys)
        address
      end

      let(:outcome) do
        # Replace the Address.new call with our mock
        allow(Address).to receive(:new).and_return(address)

        described_class.run(
          profile: profile,
          update_attribute: "company_address_details",
          attrs: { company_address_details: address_details }
        )
      end

      it "updates the profile address details and derived fields" do
        outcome
        expect(profile.reload.company_address_details).to include(address_details.stringify_keys)
        expect(profile.reload.company_address).to eq(pure_address)
        expect(profile.reload.company_zip_code).to eq(zip_code)
      end

      it "updates the shop address details and derived fields" do
        outcome
        expect(shop.reload.address_details).to include(address_details.stringify_keys)
        expect(shop.reload.address).to eq(pure_address)
        expect(shop.reload.zip_code).to eq(zip_code)
      end
    end

    context "when updating logo" do
      # Create a test file for the logo
      let(:logo_file) do
        fixture_file_upload(
          Rails.root.join('spec', 'fixtures', 'files', 'sample_image.png'),
          'image/png'
        )
      end

      let(:outcome) do
        # Ensure the Shops::Update::CONTENT_TYPES constant is defined for the test
        stub_const("Shops::Update::CONTENT_TYPES", ['image/png'])

        described_class.run(
          profile: profile,
          update_attribute: "logo",
          attrs: { logo: logo_file }
        )
      end

      it "attaches the logo to the profile" do
        expect { outcome }.to change { profile.reload.logo.attached? }.from(false).to(true)
      end

      it "attaches the same logo to the shop" do
        expect { outcome }.to change { shop.reload.logo.attached? }.from(false).to(true)
      end
    end
  end
end
