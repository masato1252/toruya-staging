require "rails_helper"

RSpec.describe BookingPage do
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
