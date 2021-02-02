# frozen_string_literal: true

require "rails_helper"

RSpec.describe Menus::RetrieveRepeatingDates do
  before do
    Timecop.freeze(Time.zone.local(2016, 9, 20, 8)) # Tuesday
  end

  describe "#repeating_dates" do
    let(:shop) { FactoryBot.create(:shop) }
    let(:menu) { FactoryBot.create(:menu, shop: shop) }
    let(:menu_rule) { FactoryBot.create(:menu_reservation_setting_rule, menu: menu, repeats: 7) }

    context "when reservation_setting is for all business_days" do
      let!(:reservation_setting) { FactoryBot.create(:reservation_setting, menu: menu) }

      context "when there is no business_schedules, Monday ~ Friday is working_day" do
        it "returns expected dates" do
          expect(Menus::RetrieveRepeatingDates.run!(
            reservation_setting_id: reservation_setting.id,
            shop_ids: [shop.id],
            repeats: menu_rule.repeats,
            start_date: menu_rule.start_date
          )).to eq([
            {
              shop: shop,
              dates: [Date.new(2016, 9, 20), Date.new(2016, 9, 21), Date.new(2016, 9, 23),
                      Date.new(2016, 9, 26), Date.new(2016, 9, 27), Date.new(2016, 9, 28), Date.new(2016, 9, 29)]
            }
          ])
        end
      end

      context "when shop only Monday to Friday are business_days" do
        before do
          5.times do |n|
            FactoryBot.create(:business_schedule, shop: shop,
                               start_time: Time.zone.local(2016, 9, 19 + n, 8),
                               end_time: Time.zone.local(2016, 9, 19 + n , 18))
          end
        end
        it "returns expected dates" do
          expect(Menus::RetrieveRepeatingDates.run!(
            reservation_setting_id: reservation_setting.id,
            shop_ids: [shop.id],
            repeats: menu_rule.repeats,
            start_date: menu_rule.start_date
          )).to eq([
            {
              shop: shop,
              dates: [Date.new(2016, 9, 20), Date.new(2016, 9, 21), Date.new(2016, 9, 23),
                      Date.new(2016, 9, 26), Date.new(2016, 9, 27), Date.new(2016, 9, 28), Date.new(2016, 9, 29)]
            }
          ])
          # 9/22 is Holiday in Japan
        end
      end
    end

    context "when reservation_setting is weekly repeat" do
      let!(:reservation_setting) { FactoryBot.create(:reservation_setting, :weekly, menu: menu, days_of_week: [1, 3, 5]) }

      context "when there is no business_schedules, Monday ~ Friday is working_day" do
        it "returns expected dates" do
          expect(Menus::RetrieveRepeatingDates.run!(
            reservation_setting_id: reservation_setting.id,
            shop_ids: [shop.id],
            repeats: menu_rule.repeats,
            start_date: menu_rule.start_date
          )).to eq([
            {
              shop: shop,
              dates: [Date.new(2016, 9, 21), Date.new(2016, 9, 23),
                      Date.new(2016, 9, 26), Date.new(2016, 9, 28), Date.new(2016, 9, 30),
                      Date.new(2016, 10, 3), Date.new(2016, 10, 5)]
            }
          ])
        end
      end

      context "when shop only Monday and Wednesday are business_days" do
        before do
          # Monday
          FactoryBot.create(:business_schedule, shop: shop,
                             start_time: Time.zone.local(2016, 9, 19, 8),
                             end_time: Time.zone.local(2016, 9, 19, 18))
          # Wednesday
          FactoryBot.create(:business_schedule, shop: shop,
                             start_time: Time.zone.local(2016, 9, 21, 8),
                             end_time: Time.zone.local(2016, 9, 21, 18))
        end

        it "returns expected dates" do
          expect(Menus::RetrieveRepeatingDates.run!(
            reservation_setting_id: reservation_setting.id,
            shop_ids: [shop.id],
            repeats: menu_rule.repeats,
            start_date: menu_rule.start_date
          )).to eq([
            {
              shop: shop,
              dates: [Date.new(2016, 9, 21),
                      Date.new(2016, 9, 26), Date.new(2016, 9, 28),
                      Date.new(2016, 10, 3), Date.new(2016, 10, 5),
                      Date.new(2016, 10, 12),
                      Date.new(2016, 10, 17)]
            }
          ])
          # 10/10 is Holiday in Japan
        end
      end
    end

    context "when reservation_setting is monthly repeat" do
      let(:menu_rule) { FactoryBot.create(:menu_reservation_setting_rule, menu: menu, repeats: 3) }

      context "when reservation_setting is number_of_day_monthly repeating" do
        let!(:reservation_setting) { FactoryBot.create(:reservation_setting, :number_of_day_monthly, menu: menu, day: 15) }

        context "when there is no business_schedules, Monday ~ Friday is working_day" do
          it "returns expected dates" do
            expect(Menus::RetrieveRepeatingDates.run!(
              reservation_setting_id: reservation_setting.id,
              shop_ids: [shop.id],
              repeats: menu_rule.repeats,
              start_date: menu_rule.start_date
            )).to eq([{
              shop: shop,
              dates: [Date.new(2016, 11, 15), Date.new(2016, 12, 15), Date.new(2017, 2, 15)]
            }
            ])
          end
        end
      end

      context "when reservation_setting is number_of_day_monthly repeating" do
        let(:menu_rule) { FactoryBot.create(:menu_reservation_setting_rule, menu: menu, repeats: 5) }
        let!(:reservation_setting) { FactoryBot.create(:reservation_setting, :day_of_week_monthly,
                                                        menu: menu,
                                                        days_of_week: [1, 2], nth_of_week: 2) }

        context "when there is no business_schedules, Monday ~ Friday is working_day" do
          it "returns expected dates" do
            expect(Menus::RetrieveRepeatingDates.run!(
              reservation_setting_id: reservation_setting.id,
              shop_ids: [shop.id],
              repeats: menu_rule.repeats,
              start_date: menu_rule.start_date
            )).to eq([{
              shop: shop,
              dates: [Date.new(2016, 10, 11), Date.new(2016, 11, 8), Date.new(2016, 11, 14), Date.new(2016, 12, 12), Date.new(2016, 12, 13)]
            }
            ])
          end
        end
      end
    end
  end
end
