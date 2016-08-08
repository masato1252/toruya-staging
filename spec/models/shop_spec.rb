require 'rails_helper'

RSpec.describe Shop, type: :model do
  context "#available_time" do
    let(:shop) { FactoryGirl.create(:shop) }
    let(:now) { Time.now }
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
end
