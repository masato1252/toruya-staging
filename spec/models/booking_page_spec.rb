# frozen_string_literal: true

require "rails_helper"

RSpec.describe BookingPage do
  describe "#primary_product" do
    let(:user) { FactoryBot.create(:user) }
    let(:booking_page) { FactoryBot.create(:booking_page, user: user) }

    context "when booking_page has primary and secondary booking_options" do
      let!(:primary_high) do
        FactoryBot.create(:booking_option, :primary, user: user, amount: 3000.to_money(:jpy), booking_pages: [booking_page])
      end
      let!(:primary_low) do
        FactoryBot.create(:booking_option, :primary, user: user, amount: 2000.to_money(:jpy), booking_pages: [booking_page])
      end
      let!(:secondary_lowest) do
        FactoryBot.create(:booking_option, :secondary, user: user, amount: 500.to_money(:jpy), booking_pages: [booking_page])
      end

      it "returns the cheapest primary (main) booking_option, ignoring secondary (sub) options" do
        expect(booking_page.primary_product).to eq(primary_low)
      end

      it "exposes product_price as the cheapest primary option's amount" do
        expect(booking_page.product_price).to eq(2000.to_money(:jpy))
      end
    end

    context "when booking_page only has secondary booking_options" do
      before do
        FactoryBot.create(:booking_option, :secondary, user: user, amount: 500.to_money(:jpy), booking_pages: [booking_page])
      end

      it "returns nil" do
        expect(booking_page.primary_product).to be_nil
      end

      it "returns nil for product_price" do
        expect(booking_page.product_price).to be_nil
      end
    end
  end

  describe "#ended?" do
    context "when end_at exists and today is over the end_at" do
      let(:booking_page) { FactoryBot.create(:booking_page, end_at: Time.zone.now.advance(minutes: -1)) }

      it "returns true" do
        expect(booking_page).to be_ended
      end
    end


    context "when special_dates exists" do
      context "when there is no special available date to book" do
        let(:special_date) { FactoryBot.create(:booking_page_special_date, start_at: Subscription.today ) }
        let(:booking_page) { special_date.booking_page.tap { |b| b.update_columns(end_at: nil) } }

        it "returns true" do
          expect(booking_page).to be_ended
        end
      end

      context "when there is special available date to book" do
        let(:special_date) { FactoryBot.create(:booking_page_special_date, start_at: Subscription.today.advance(days: 2) ) }
        let(:booking_page) { special_date.booking_page.tap { |b| b.update_columns(end_at: nil) } }

        it "returns false" do
          expect(booking_page).not_to be_ended
        end
      end
    end
  end
end
