# frozen_string_literal: true

require "rails_helper"

RSpec.describe Booking::AvailableBookingTimesForTimeslot do
  before do
    # Sunday, one day before booking date
    Timecop.freeze(today)
  end

  let(:today) { Time.zone.local(2019, 5, 12) }
  let(:business_schedule) { FactoryBot.create(:business_schedule) }
  let(:shop) { business_schedule.shop }
  let(:user) { shop.user }
  let(:staff) { FactoryBot.create(:staff, :full_time, :owner, shop: shop, user: user) }
  let(:booking_page) { FactoryBot.create(:booking_page, user: user, shop: shop, overbooking_restriction: overbooking_restriction, end_at: nil) }
  let(:booking_option) { FactoryBot.create(:booking_option, :single_menu, user: user, minutes: 20) }
  let(:booking_option2) { FactoryBot.create(:booking_option, :single_menu, user: user, minutes: 20) }
  let(:special_dates) {[
    "{\"start_at_date_part\":\"2019-05-13\",\"start_at_time_part\":\"09:00\",\"end_at_date_part\":\"2019-05-13\",\"end_at_time_part\":\"14:00\"}",
  ]}
  let(:overbooking_restriction) { true }
  let!(:staff_menu1) { FactoryBot.create(:staff_menu, menu: booking_option.menus.first, staff: staff, max_customers: 1) }
  let!(:shop_menu1) { FactoryBot.create(:shop_menu, menu: booking_option.menus.first, shop: shop, max_seat_number: 1) }
  let!(:staff_menu2) { FactoryBot.create(:staff_menu, menu: booking_option2.menus.first, staff: staff, max_customers: 1) }
  let!(:shop_menu2) { FactoryBot.create(:shop_menu, menu: booking_option2.menus.first, shop: shop, max_seat_number: 1) }
  let(:args) do
    {
      shop: shop,
      booking_page: booking_page,
      special_dates: special_dates,
      booking_option_ids: [booking_option.id],
      staff_ids: [staff.id],
      interval: 60,
      overbooking_restriction: overbooking_restriction
    }
  end
  let(:outcome) { described_class.run(args) }

  it "returns expected result, returns all available booking time" do
    args[:booking_option_ids] = [booking_option.id]
    result = outcome.result

    expect(result).to eq({
      Time.zone.local(2019, 5, 13, 9)  => [[booking_option.id]],
      Time.zone.local(2019, 5, 13, 10) => [[booking_option.id]],
      Time.zone.local(2019, 5, 13, 11) => [[booking_option.id]],
      Time.zone.local(2019, 5, 13, 12) => [[booking_option.id]],
      Time.zone.local(2019, 5, 13, 13) => [[booking_option.id]]
    })
  end

  context "when try to book multiple booking options" do
    it "returns expected result, returns all available booking time" do
      args[:booking_option_ids] = [booking_option.id, booking_option2.id]
      result = outcome.result

      expect(result).to eq({
        Time.zone.local(2019, 5, 13, 9)  => [[booking_option.id, booking_option2.id]],
        Time.zone.local(2019, 5, 13, 10) => [[booking_option.id, booking_option2.id]],
        Time.zone.local(2019, 5, 13, 11) => [[booking_option.id, booking_option2.id]],
        Time.zone.local(2019, 5, 13, 12) => [[booking_option.id, booking_option2.id]],
      })
    end
  end

  context "when booking option only sells during a period" do
    let(:booking_option) { FactoryBot.create(:booking_option, :single_menu, user: user,
                                             start_at: Time.new(2019, 5, 14),
                                             end_at: Time.new(2019, 5, 26)) }
    it "returns expected result" do
      result = outcome.result

      expect(result).to eq({})
    end

    it "returns expected result" do
      args[:booking_option_ids] = [booking_option2.id]
      result = outcome.result

      expect(result).to eq({
        Time.zone.local(2019, 5, 13, 9)  => [[booking_option2.id]],
        Time.zone.local(2019, 5, 13, 10) => [[booking_option2.id]],
        Time.zone.local(2019, 5, 13, 11) => [[booking_option2.id]],
        Time.zone.local(2019, 5, 13, 12) => [[booking_option2.id]],
        Time.zone.local(2019, 5, 13, 13) => [[booking_option2.id]]
      })
    end
  end

  context "when booking page got special booking start time" do
    let(:booking_page) { FactoryBot.create(:booking_page, end_at: nil, specific_booking_start_times: ["09:00", "13:00"], user: user, shop: shop, overbooking_restriction: overbooking_restriction) }

    it "returns expected result, returns all available booking time" do
      result = outcome.result

      expect(result).to eq({
        Time.zone.local(2019, 5, 13, 9)  => [[booking_option.id]],
        Time.zone.local(2019, 5, 13, 13) => [[booking_option.id]]
      })
    end
  end

  context "when today is 2019-05-13" do
    # Default booking page limit day is 1, that means you couldn't book today
    let(:today) { Time.zone.local(2019, 5, 13) }

    it "returns expected result" do
      result = outcome.result

      expect(result).to eq({ })
    end
  end

  context "when there is existing reservation" do
    before do
      # The free gap is 9: 00 ~ 10:10
      # Because of the interval time,
      # 10:00 ~ 11: 10 is not available(overlap with existing reservation start time)
      # 12:00 ~ 13: 10 is not available(overlap with existing reservation end time)
      # but becasue the existing reservation still capable to handle one more customer,
      # so 11:00 ~ 12:10 is available, but it only for the booking_option menu
      # because staff already work for booking_option menu, they couldn't work on booking_option2 at the same time
      FactoryBot.create(:reservation, shop: shop, staffs: staff,
                        menus: [booking_option.menus.first],
                        start_time:     Time.zone.local(2019, 5, 13, 11, 00),
                        force_end_time: Time.zone.local(2019, 5, 13, 12, 10))
    end

    context "when the existing reservation allow new customer to join" do
      let!(:staff_menu1) { FactoryBot.create(:staff_menu, menu: booking_option.menus.first, staff: staff, max_customers: 2) }
      let!(:shop_menu1) { FactoryBot.create(:shop_menu, menu: booking_option.menus.first, shop: shop, max_seat_number: 2) }
      let!(:staff_menu2) { FactoryBot.create(:staff_menu, menu: booking_option2.menus.first, staff: staff, max_customers: 2) }
      let!(:shop_menu2) { FactoryBot.create(:shop_menu, menu: booking_option2.menus.first, shop: shop, max_seat_number: 2) }

      it "booking the booking option already has reservation, returns expected result, returns all available booking time" do
        result = outcome.result

        expect(result).to eq({
          Time.zone.local(2019, 5, 13, 9)  => [[booking_option.id]],
          Time.zone.local(2019, 5, 13, 11) => [[booking_option.id]],
          Time.zone.local(2019, 5, 13, 13) => [[booking_option.id]]
        })

        args[:booking_option_ids] = [booking_option2.id]
      end

      it "booking the booking option2 doesn't have reservation, returns expected result, returns all available booking time" do
        args[:booking_option_ids] = [booking_option2.id]
        result = outcome.result

        expect(result).to eq({
          Time.zone.local(2019, 5, 13, 9)  => [[booking_option2.id]],
          Time.zone.local(2019, 5, 13, 13) => [[booking_option2.id]]
        })
      end
    end

    context "when the existing reservation doesn't have enough space for new customer to join" do
      it "returns expected result, returns all available booking time" do
        result = outcome.result

        expect(result).to eq({
          Time.zone.local(2019, 5, 13, 9)  => [[booking_option.id]],
          Time.zone.local(2019, 5, 13, 13) => [[booking_option.id]]
        })
      end
    end

    context "when allow to overbooking" do
      let(:overbooking_restriction) { false }

      it "returns expected result, returns all available booking time" do
        result = outcome.result

        expect(result).to eq({
          Time.zone.local(2019, 5, 13, 9)  => [[booking_option.id]],
          Time.zone.local(2019, 5, 13, 11) => [[booking_option.id]],
          Time.zone.local(2019, 5, 13, 13) => [[booking_option.id]]
        })
      end

      context "when try to book different booking options" do
        it "returns expected result, returns all available booking time" do
          args[:booking_option_ids] = [booking_option2.id]
          result = outcome.result

          expect(result).to eq({
            Time.zone.local(2019, 5, 13, 9)  => [[booking_option2.id]],
            Time.zone.local(2019, 5, 13, 13) => [[booking_option2.id]]
          })
        end
      end
    end

    context "when the booking option's menu is no-manpower type(min_staffs_number is 0)" do
      let(:menu) { FactoryBot.create(:menu, :with_reservation_setting, :no_manpower, user: user) }
      let(:booking_option) { FactoryBot.create(:booking_option, user: user, menus: [menu]) }

      # The no-manpower menu still need available staff
      it "returns expected result, returns all available booking time" do
        result = outcome.result

        expect(result).to eq({
          Time.zone.local(2019, 5, 13, 9)  => [[booking_option.id]],
          Time.zone.local(2019, 5, 13, 10) => [[booking_option.id]],
          Time.zone.local(2019, 5, 13, 11) => [[booking_option.id]],
          Time.zone.local(2019, 5, 13, 12) => [[booking_option.id]],
          Time.zone.local(2019, 5, 13, 13) => [[booking_option.id]]
        })
      end
    end
  end
end
