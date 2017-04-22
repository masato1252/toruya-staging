require "rails_helper"

RSpec.describe Reservable::Time do
  before do
    Timecop.freeze(Time.local(2016, 12, 22, 10))
  end

  let(:user) { shop.user }
  let(:shop) { FactoryGirl.create(:shop) }
  let(:now) { Time.zone.now }
  let(:date) { now.to_date }

  describe "#execute" do
    context "when shop has custom schedule" do
      let!(:custom_schedule) { FactoryGirl.create(:custom_schedule, shop: shop, staff: nil,
                                                  start_time: now.beginning_of_day + 8.hours,
                                                  end_time: now.beginning_of_day + 16.hours) }

      context "when shop has business_schedule" do
        let!(:business_schedule) { FactoryGirl.create(:business_schedule, shop: shop,
                                                      start_time: (now.beginning_of_day + 7.hours).advance(weeks: -1),
                                                      end_time: (now.beginning_of_day + 18.hours).advance(weeks: -1)) }

        context "when custom_schedule end time >= schedule end_time" do
          it "is invalid" do
            expect(Reservable::Time.run(shop: shop, date: date)).to be_invalid
          end
        end

        context "when custom_schedule end time < schedule end_time" do
          let!(:business_schedule) { FactoryGirl.create(:business_schedule, shop: shop,
                                                        start_time: (now.beginning_of_day + 7.hours).advance(weeks: 1),
                                                        end_time: (now.beginning_of_day + 18.hours).advance(weeks: 1)) }
          it "returns available time range" do
            expect(Reservable::Time.run!(shop: shop, date: date)).to eq(custom_schedule.end_time..business_schedule.end_time)
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
        let(:shop) { FactoryGirl.create(:shop, holiday_working: true) }
        let!(:business_schedule) { FactoryGirl.create(:business_schedule, shop: shop,
                                                      start_time: (now.beginning_of_day + 7.hours).advance(weeks: -1),
                                                      end_time: (now.beginning_of_day + 18.hours).advance(weeks: -1)) }


        it "returns available time range" do
          expect(Reservable::Time.run!(shop: shop, date: date)).to eq(business_schedule.start_time..business_schedule.end_time)
        end
      end

      context "when shop does not need to work" do
        it "is invalid" do
          expect(Reservable::Time.run(shop: shop, date: date)).to be_invalid
        end
      end
    end
  end
end
