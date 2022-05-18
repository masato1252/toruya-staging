# frozen_string_literal: true

require "rails_helper"

RSpec.describe ::CustomMessages::Customers::Template do
  let(:product) { nil }
  let(:scenario) { nil }
  let(:args) do
    {
      product: product,
      scenario: scenario
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    context "when product is nil" do
      let(:scenario) { described_class::BOOKING_PAGE_BOOKED }

      context "when shop had no phone number" do
        let(:shop) { FactoryBot.create(:shop, phone_number: nil) }
        let(:product) { FactoryBot.create(:booking_page, shop: shop) }

        it "returns template without phone number part message" do
          expect(outcome.result).to eq(I18n.t("customer.notifications.sms.booking"))
        end
      end
    end

    context "when product is a booking page" do
      let(:product) { FactoryBot.create(:booking_page) }
      let(:scenario) { described_class::BOOKING_PAGE_BOOKED }

      context "when shop got phone number" do
        it "returns template with phone number part message" do
          expect(outcome.result).to eq("#{I18n.t("customer.notifications.sms.booking")}#{I18n.t("customer.notifications.sms.change_from_phone_number")}")
        end
      end

      context "when shop had no phone number" do
        let(:shop) { FactoryBot.create(:shop, phone_number: nil) }
        let(:product) { FactoryBot.create(:booking_page, shop: shop) }

        it "returns template without phone number part message" do
          expect(outcome.result).to eq(I18n.t("customer.notifications.sms.booking"))
        end
      end
    end
  end
end
