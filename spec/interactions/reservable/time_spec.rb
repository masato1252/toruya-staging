# frozen_string_literal: true

require "rails_helper"

RSpec.describe Reservable::Time do
  before do
    Timecop.freeze(Time.local(2016, 12, 22, 10))
  end

  let(:user) { shop.user }
  let(:shop) { FactoryBot.create(:shop) }
  let(:now) { Time.zone.now }
  let(:date) { now.to_date }

  describe "#execute" do
    context "when shop has closed custom schedule" do
      let!(:custom_schedule) { FactoryBot.create(:custom_schedule, :for_shop, shop: shop,
                                                  start_time: now.beginning_of_day + 8.hours,
                                                  end_time: now.beginning_of_day + 16.hours) }

      context "when shop has business_schedule" do
        let!(:business_schedule) { FactoryBot.create(:business_schedule, shop: shop,
                                                      start_time: (now.beginning_of_day + 7.hours).advance(weeks: -1),
                                                      end_time: (now.beginning_of_day + 18.hours).advance(weeks: -1)) }

        context "when custom_schedule end time >= schedule end_time" do
          it "is invalid" do
            expect(Reservable::Time.run(shop: shop, date: date)).to be_invalid
          end
        end

        context "when custom_schedule end time < schedule end_time" do
          let!(:business_schedule) { FactoryBot.create(:business_schedule, shop: shop,
                                                        start_time: (now.beginning_of_day + 7.hours).advance(weeks: 1),
                                                        end_time: (now.beginning_of_day + 18.hours).advance(weeks: 1)) }
          it "returns available time range" do
            expect(Reservable::Time.run!(shop: shop, date: date)).to eq([ custom_schedule.end_time..business_schedule.end_time ])
          end
        end
      end

      context "when shop dose not have business_schedule" do
        it "is invalid" do
          expect(Reservable::Time.run(shop: shop, date: date)).to be_invalid
        end
      end
    end

    context "when that date is Japan holiday" do
      before { Timecop.freeze(Date.new(2016, 1, 1)) }

      context "when shop needs to work" do
        let(:shop) { FactoryBot.create(:shop, holiday_working: true) }
        let!(:business_schedule) { FactoryBot.create(:business_schedule, :holiday_working, shop: shop,
                                                      start_time: (now.beginning_of_day + 7.hours).advance(weeks: -1),
                                                      end_time: (now.beginning_of_day + 18.hours).advance(weeks: -1)) }


        it "returns available time range" do
          expect(Reservable::Time.run!(shop: shop, date: date)).to eq([ business_schedule.start_time_on(date)..business_schedule.end_time_on(date) ])
        end
      end

      context "when shop does not need to work" do
        it "is invalid" do
          expect(Reservable::Time.run(shop: shop, date: date)).to be_invalid
        end
      end
    end

    context "when booking_page had business_schedule" do
      let(:booking_page) { FactoryBot.create(:booking_page, shop: shop) }
      let!(:business_schedule) { FactoryBot.create(:business_schedule,
                                                   shop: shop,
                                                   booking_page: booking_page,
                                                   day_of_week: now.wday,
                                                   start_time: (now.beginning_of_day + 7.hours).advance(weeks: -1),
                                                   end_time: (now.beginning_of_day + 18.hours).advance(weeks: -1)) }
      let!(:other_business_schedule) { FactoryBot.create(:business_schedule,
                                                         shop: shop,
                                                         booking_page: booking_page,
                                                         day_of_week: now.wday + 1,
                                                         start_time: (now.beginning_of_day + 7.hours).advance(weeks: -1),
                                                         end_time: (now.beginning_of_day + 18.hours).advance(weeks: -1)) }


      it "returns available time range" do
        expect(Reservable::Time.run!(shop: shop, booking_page: booking_page, date: date)).to eq([ business_schedule.start_time_on(date)..business_schedule.end_time_on(date) ])
      end
    end

    context "when booking_page has special date" do
      let(:booking_page) { FactoryBot.create(:booking_page, shop: shop) }
      let!(:booking_page_special_date1) { FactoryBot.create(:booking_page_special_date,
                                                          booking_page: booking_page,
                                                          start_at: now,
                                                          end_at: now + 1.hour) }
      let!(:booking_page_special_date2) { FactoryBot.create(:booking_page_special_date,
                                                          booking_page: booking_page,
                                                          start_at: now + 2.hours,
                                                          end_at: now + 3.hours) }

      it "returns available time range" do
        expect(Reservable::Time.run!(shop: shop, booking_page: booking_page, date: date)).to eq([
          booking_page_special_date1.start_at..booking_page_special_date1.end_at,
          booking_page_special_date2.start_at..booking_page_special_date2.end_at
        ])
      end
    end
  end
end
