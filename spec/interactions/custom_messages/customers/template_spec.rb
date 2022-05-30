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

    context "when product is a shop" do
      let(:product) { FactoryBot.create(:shop) }
      let(:scenario) { described_class::BOOKING_PAGE_BOOKED }
      let!(:custom_message) { FactoryBot.create(:custom_message, service: product, scenario: scenario) }

      it "returns shop's custom message" do
        expect(outcome.result).to eq(custom_message.content)
      end
    end

    context "when custom_message_only is true" do
      context "when there is no custom message match" do
        it "returns nil" do
          args.merge!(custom_message_only: true)

          expect(outcome.result).to be_nil
        end
      end
    end
  end
end
