# frozen_string_literal: true

require "rails_helper"

RSpec.describe Shops::UpdateFromProfile do
  let(:profile) { FactoryBot.create(:profile) }
  let(:user) { profile.user }
  let(:shop) { FactoryBot.create(:shop, user: user) }
  let(:outcome) { described_class.run(shop: shop) }

  describe "#execute" do
    before do
      profile.update!(
        company_name: "Test Company",
        company_phone_number: "1234567890",
        company_email: "test@example.com",
        website: "https://example.com",
        company_zip_code: "12345",
        company_address: "Test Address",
        company_address_details: { street1: "123 Main St" }
      )
    end

    it "updates shop with profile data" do
      outcome

      expect(shop.reload.name).to eq(profile.company_name)
      expect(shop.short_name).to eq(profile.company_name)
      expect(shop.phone_number).to eq(profile.company_phone_number)
      expect(shop.email).to eq(profile.company_email)
      expect(shop.website).to eq(profile.website)
      expect(shop.zip_code).to eq(profile.company_zip_code)
      expect(shop.address).to eq(profile.company_address)
      expect(shop.address_details).to eq(profile.company_address_details)
    end

    context "when profile has a logo" do
      before do
        profile.logo.attach(
          io: File.open(Rails.root.join("spec", "fixtures", "files", "sample_image.png")),
          filename: "sample_image.png",
          content_type: "image/png"
        )
      end

      it "copies logo from profile to shop" do
        outcome

        expect(shop.logo).to be_attached
        expect(shop.logo.filename).to eq(profile.logo.filename)
      end
    end

    context "when profile does not exist" do
      before do
        profile.destroy
      end

      it "adds an error" do
        expect(outcome).to be_invalid
        expect(outcome.errors[:profile]).to include("not found")
      end
    end
  end
end