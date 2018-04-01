require "rails_helper"

RSpec.describe Staffs::WorkingDateRules do
  let(:shop) { FactoryBot.create(:shop) }
  let(:staff) { FactoryBot.create(:staff) }
  let(:date_range) { Date.today.beginning_of_month..Date.today.end_of_month }
  let(:args) do
    {
      shop: shop,
      staff: staff,
      date_range: date_range
    }
  end

  let(:outcome) { described_class.run!(args)}

  describe "#execute" do
    it "return expected result" do
      expect(outcome).to eq({
        full_time: false,
        shop_working_on_holiday: false,
        shop_working_wdays: [],
        staff_working_wdays: [],
        working_dates: [],
        off_dates: [],
        holidays: Holidays.between(date_range.first, date_range.last).map { |holiday| holiday[:date] }
      })
    end

    context "when staff is full time in this shop" do
      before do
        FactoryBot.create(:business_schedule, :full_time, shop: shop, staff: staff)
      end

      it "return expected result" do
        expect(outcome).to eq({
          full_time: true,
          shop_working_on_holiday: false,
          shop_working_wdays: [],
          staff_working_wdays: [],
          working_dates: [],
          off_dates: [],
          holidays: Holidays.between(date_range.first, date_range.last).map { |holiday| holiday[:date] }
        })
      end

      context "when shop only open on Monday" do
        let(:day_of_week) { 1 }
        before do
          FactoryBot.create(:business_schedule, :opened, shop: shop, day_of_week: day_of_week)
        end

        it "return expected result" do
          expect(outcome).to eq({
            full_time: true,
            shop_working_on_holiday: false,
            shop_working_wdays: [day_of_week],
            staff_working_wdays: [],
            working_dates: [],
            off_dates: [],
            holidays: Holidays.between(date_range.first, date_range.last).map { |holiday| holiday[:date] }
          })
        end
      end
    end

    context "when staff is part time in this shop" do
      context "when staff only work on Monday" do
        let(:day_of_week) { 1 }
        before do
          FactoryBot.create(:business_schedule, :opened, shop: shop, staff: staff, day_of_week: day_of_week)
        end

        it "return expected result" do
          expect(outcome).to eq({
            full_time: false,
            shop_working_on_holiday: false,
            shop_working_wdays: [],
            staff_working_wdays: [day_of_week],
            working_dates: [],
            off_dates: [],
            holidays: Holidays.between(date_range.first, date_range.last).map { |holiday| holiday[:date] }
          })
        end
      end

      context "when staff only work on particular one day" do
        let(:particular_date) { Date.today.beginning_of_month.tomorrow }
        before do
          FactoryBot.create(:custom_schedule, :opened, shop: shop, staff: staff, start_time: particular_date.beginning_of_day)
        end

        it "return expected result" do
          expect(outcome).to eq({
            full_time: false,
            shop_working_on_holiday: false,
            shop_working_wdays: [],
            staff_working_wdays: [],
            working_dates: [particular_date],
            off_dates: [],
            holidays: Holidays.between(date_range.first, date_range.last).map { |holiday| holiday[:date] }
          })
        end
      end
    end

    context "when shop is off on particular date" do
      let(:particular_date) { Date.today.beginning_of_month.tomorrow }
      before do
        FactoryBot.create(:custom_schedule, :closed, :for_shop, shop: shop, start_time: particular_date.beginning_of_day)
      end

      it "return expected result" do
        expect(outcome).to eq({
          full_time: false,
          shop_working_on_holiday: false,
          shop_working_wdays: [],
          staff_working_wdays: [],
          working_dates: [],
          off_dates: [particular_date],
          holidays: Holidays.between(date_range.first, date_range.last).map { |holiday| holiday[:date] }
        })
      end
    end

    context "when staff is off on particular date and that date shop is reservable" do
      let(:particular_date) { Date.today.beginning_of_month.tomorrow }
      before do
        FactoryBot.create(:custom_schedule, :closed, shop: shop, staff: staff,
                          start_time: particular_date.beginning_of_day,
                          end_time: particular_date.end_of_day)
      end

      context "when staff is only off all day" do
        before do
          allow(Shops::StaffsWorkingSchedules).to receive(:run).and_return(spy(
            valid?: true,
            result: { staff => { time: nil, reason: "foo" } }
          ))
        end

        it "return expected result" do
          expect(outcome).to eq({
            full_time: false,
            shop_working_on_holiday: false,
            shop_working_wdays: [],
            staff_working_wdays: [],
            working_dates: [],
            off_dates: [particular_date],
            holidays: Holidays.between(date_range.first, date_range.last).map { |holiday| holiday[:date] }
          })
        end
      end

      context "when staff is only off in part of time" do
        before do
          allow(Shops::StaffsWorkingSchedules).to receive(:run).and_return(spy(
            valid?: true,
            result: { staff => { time: particular_date.middle_of_day, reason: "foo" } }
          ))
        end

        it "return expected result" do
          expect(outcome).to eq({
            full_time: false,
            shop_working_on_holiday: false,
            shop_working_wdays: [],
            staff_working_wdays: [],
            working_dates: [],
            off_dates: [],
            holidays: Holidays.between(date_range.first, date_range.last).map { |holiday| holiday[:date] }
          })
        end
      end
    end
  end
end
