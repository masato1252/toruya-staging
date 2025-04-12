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
      expect(outcome).to be_valid
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
      let(:image_path) { Rails.root.join("spec", "fixtures", "files", "sample_image.png") }

      before do
        allow(Rails.application.routes.url_helpers).to receive(:url_for).and_return("http://example.com/logo.png")
        allow(URI).to receive(:open).and_return(File.open(image_path))
        profile.logo.attach(
          io: File.open(image_path),
          filename: "sample_image.png",
          content_type: "image/png"
        )
      end

      it "copies logo from profile to shop" do
        expect(outcome).to be_valid
        expect(shop.logo).to be_attached
        expect(shop.logo.filename.to_s).to eq("sample_image.png")
      end

      context "when logo copy fails" do
        before do
          allow(URI).to receive(:open).and_raise(StandardError.new("Failed to copy logo"))
        end

        it "adds an error but still updates other attributes" do
          outcome
          expect(outcome.errors.details[:logo]).to include(error: :copy_failed)
          expect(shop.reload.name).to eq(profile.company_name)
        end
      end
    end

    context "when profile does not exist" do
      before do
        user.profile.destroy
        user.reload
      end

      it "adds an error" do
        expect(outcome).to be_invalid
        expect(outcome.errors.details[:profile]).to include(error: :not_found)
      end
    end

    context "when user does not exist" do
      before do
        shop.update_column(:user_id, nil)
      end

      it "adds an error" do
        expect(outcome).to be_invalid
        expect(outcome.errors.details[:profile]).to include(error: :not_found)
      end
    end
  end
end