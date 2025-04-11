# frozen_string_literal: true

require "rails_helper"

RSpec.describe Profiles::UpdateShopInfo do
  let(:user) { FactoryBot.create(:user) }
  let!(:profile) { FactoryBot.create(:profile, user: user) }
  let(:social_user) { FactoryBot.create(:social_user, user: user) }
  let!(:shop) { FactoryBot.create(:shop, user: user) }
  let!(:staff) { FactoryBot.create(:staff, user: user) }
  let(:params) do
    {
      company_name: "New Company Name",
      company_phone_number: "1234567890",
      zip_code: "12345",
      region: "Test Region",
      city: "Test City",
      street1: "123 Main St",
      street2: "Apt 4B"
    }
  end

  describe "#execute" do
    subject(:outcome) { described_class.run(user: user, social_user: social_user, params: params) }

    before do
      # Ensure user has a phone number
      user.update!(phone_number: "0987654321")

      # Create proper stubs for ActiveInteraction objects
      social_users_connect = instance_double(SocialUsers::Connect)
      allow(social_users_connect).to receive(:valid?).and_return(true)
      allow(social_users_connect).to receive(:invalid?).and_return(false)
      allow(social_users_connect).to receive(:result).and_return(social_user)
      allow(SocialUsers::Connect).to receive(:run).and_return(social_users_connect)

      business_schedules_create = instance_double(BusinessSchedules::Create)
      allow(business_schedules_create).to receive(:valid?).and_return(true)
      allow(business_schedules_create).to receive(:invalid?).and_return(false)
      allow(business_schedules_create).to receive(:result).and_return(true)
      allow(BusinessSchedules::Create).to receive(:run).and_return(business_schedules_create)

      menus_update = instance_double(Menus::Update)
      allow(menus_update).to receive(:valid?).and_return(true)
      allow(menus_update).to receive(:invalid?).and_return(false)
      allow(menus_update).to receive(:result).and_return(true)
      allow(Menus::Update).to receive(:run).and_return(menus_update)

      # Create a reservation setting
      user.reservation_settings.create(
        name: I18n.t("common.full_working_time"),
        short_name: I18n.t("common.full_working_time"),
        day_type: "business_days"
      )

      # Allow the job to be enqueued
      ActiveJob::Base.queue_adapter = :test
    end

    it "updates profile with new company information" do
      outcome

      profile.reload
      expect(profile.company_name).to eq("New Company Name")
      expect(profile.company_phone_number).to eq("1234567890")
      expect(profile.company_zip_code).to eq("12345")
      expect(profile.company_address).to include("Test Region")
      expect(profile.company_address).to include("Test City")
      expect(profile.company_address).to include("123 Main St")
    end

    it "updates all user's shops with the new profile data" do
      second_shop = FactoryBot.create(:shop, user: user)
      outcome

      [shop, second_shop].each do |shop|
        shop.reload
        expect(shop.name).to eq("New Company Name")
        expect(shop.short_name).to eq("New Company Name")
        expect(shop.phone_number).to eq("1234567890")
        expect(shop.zip_code).to eq("12345")
        expect(shop.address).to include("Test Region")
        expect(shop.address).to include("Test City")
        expect(shop.address).to include("123 Main St")
      end
    end

    context "when company name is not provided" do
      let(:params) do
        {
          company_phone_number: "1234567890",
          zip_code: "12345",
          region: "Test Region",
          city: "Test City",
          street1: "123 Main St",
          street2: "Apt 4B"
        }
      end

      it "uses default name format for profile and shops" do
        outcome

        expected_name = "#{user.name} #{I18n.t("common.of")}#{I18n.t("common.shop")}"
        expect(profile.reload.company_name).to eq(expected_name)
        expect(shop.reload.name).to eq(expected_name)
        expect(shop.short_name).to eq(expected_name)
      end
    end

    context "when company phone number is not provided" do
      let(:params) do
        {
          company_name: "New Company Name",
          zip_code: "12345",
          region: "Test Region",
          city: "Test City",
          street1: "123 Main St",
          street2: "Apt 4B"
        }
      end

      it "uses user's phone number for profile and shops" do
        outcome

        expect(profile.reload.company_phone_number).to eq(user.phone_number)
        expect(shop.reload.phone_number).to eq(user.phone_number)
      end
    end

    it "enqueues notification jobs" do
      expect {
        outcome
      }.to have_enqueued_job(ActiveInteractionJob)
        .with("Notifiers::Users::MessageForUserCreatedShop", { receiver: social_user })
        .and have_enqueued_job(ActiveInteractionJob)
        .with("Notifiers::Users::VideoForUserCreatedShop", { receiver: social_user })
    end
  end
end