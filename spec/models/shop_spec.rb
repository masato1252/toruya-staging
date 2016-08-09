require 'rails_helper'

RSpec.describe Shop, type: :model do
  let(:shop) { FactoryGirl.create(:shop) }
  let(:now) { Time.zone.now }

  describe "#available_time" do
    context "when shop has custom schedule" do
      let!(:custom_schedule) { FactoryGirl.create(:custom_schedule, shop: shop,
                                                 start_time: now.beginning_of_day + 8.hours,
                                                 end_time: now.beginning_of_day + 16.hours) }

      context "when shop has business_schedule" do
        let!(:business_schedule) { FactoryGirl.create(:business_schedule, shop: shop,
                                                     start_time: now.beginning_of_day + 7.hours,
                                                     end_time: now.beginning_of_day + 18.hours) }

        it "returns available time range" do
          expect(shop.available_time(now.to_date)).to eq((now.beginning_of_day + 16.hours)..(now.beginning_of_day + 18.hours))
        end
      end

      context "when shop dose not have business_schedule" do
        it "returns nil" do
          expect(shop.available_time(now.to_date)).to be_nil
        end
      end
    end

    context "when that date is Japan holiday" do
      before { Timecop.freeze(Date.new(2016, 1, 1)) }

      context "when shop needs to work" do
        let(:shop) { FactoryGirl.create(:shop, holiday_working: true) }
        let!(:business_schedule) { FactoryGirl.create(:business_schedule, shop: shop,
                                                      start_time: now.beginning_of_day + 7.hours,
                                                      end_time: now.beginning_of_day + 18.hours) }


        it "returns available time range" do
          expect(shop.available_time(now.to_date)).to eq((now.beginning_of_day + 7.hours)..(now.beginning_of_day + 18.hours))
        end
      end

      context "when shop does not need to work" do
        it "returns nil" do
          expect(shop.available_time(now.to_date)).to be_nil
        end
      end
    end
  end

  describe "#available_reservation_menus" do
    let(:menu) { FactoryGirl.create(:menu, shop: shop, minutes: 60) }
    let(:params) {{ menu: menu, reservation_type: "block" }}
    let(:time_range) { now..now.advance(minutes: 60) }

    context "when reservation time is shorter than menu required times" do
      let!(:reservation_setting) { FactoryGirl.create(:reservation_setting, params.merge(day_type: "business_days")) }
      let(:time_range) { now..now.advance(minutes: 59) }

      it "returns empty" do
        expect(shop.available_reservation_menus(time_range)).to be_empty
      end
    end

    context "when all staffs already had reservations at that time" do
    end

    context "when menus reservation is available on each business days" do
      let!(:reservation_setting) { FactoryGirl.create(:reservation_setting, params.merge(day_type: "business_days")) }

      it "returns available reservation menus" do
        expect(shop.available_reservation_menus(time_range)).to include(menu)
      end

      context "when reservation setting time is not available" do
        let!(:reservation_setting) { FactoryGirl.create(:reservation_setting, params.merge(day_type: "business_days", start_time: now.advance(minute: 0), end_time: now.advance(minutes: 59))) }

        it "returns empty" do
          expect(shop.available_reservation_menus(time_range)).to be_empty
        end
      end
    end

    context "when menus reservation is available on each Friday" do
      before { Timecop.freeze(Date.new(2016, 8, 5)) }
      let!(:reservation_setting) { FactoryGirl.create(:reservation_setting, params.merge(day_type: "weekly", day_of_week: 5)) }

      it "returns available reservation menus" do
        expect(shop.available_reservation_menus(time_range)).to include(menu)
      end
    end

    context "when menus reservation is available on second day of each Month" do
      before { Timecop.freeze(Date.new(2016, 8, 2)) }
      let!(:reservation_setting) { FactoryGirl.create(:reservation_setting, params.merge(day_type: "number_of_day_monthly", day: 2)) }

      it "returns available reservation menus" do
        expect(shop.available_reservation_menus(time_range)).to include(menu)
      end
    end

    context "when menus reservation is available on second Friday of each Month" do
      before { Timecop.freeze(Date.new(2016, 8, 12)) }
      let!(:reservation_setting) { FactoryGirl.create(:reservation_setting, params.merge(day_type: "day_of_week_monthly", nth_of_week: 2, day_of_week: 5)) }

      it "returns available reservation menus" do
        expect(shop.available_reservation_menus(time_range)).to include(menu)
      end
    end
  end
end
