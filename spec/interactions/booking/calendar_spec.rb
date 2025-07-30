# frozen_string_literal: true

require "rails_helper"
RSpec.describe Booking::Calendar do
  before do
    # Sunday, one day before booking date
    Timecop.freeze(today)
    allow(user).to receive(:premium_member?).and_return(true)
  end

  let(:today) { Time.zone.local(2019, 5, 12) }
  let(:business_schedule) { FactoryBot.create(:business_schedule) }
  let(:booking_page) { FactoryBot.create(:booking_page, end_at: nil) }
  let(:shop) { business_schedule.shop }
  let(:user) { shop.user }
  let(:date_range) { Date.current.beginning_of_month..Date.current.end_of_month.end_of_day  }
  let(:args) do
    {
      shop: shop,
      booking_page: booking_page,
      date_range: date_range,
    }
  end
  let(:outcome) do
    described_class.run(args)
  end

  context "when special_dates exists" do
    let(:staff) { FactoryBot.create(:staff, :full_time, shop: shop, user: user) }
    let(:booking_option) { FactoryBot.create(:booking_option, :single_menu, user: user) }

    before do
      FactoryBot.create(:staff_menu, menu: booking_option.menus.first, staff: staff)
      FactoryBot.create(:shop_menu, menu: booking_option.menus.first, shop: shop)

      args.merge!(booking_option_ids: [booking_option.id])
    end

    it "returns expected result" do
      special_dates = [
        "{\"start_at_date_part\":\"2019-05-13\",\"start_at_time_part\":\"01:00\",\"end_at_date_part\":\"2019-05-13\",\"end_at_time_part\":\"23:59\"}",
      ]
      args.merge!(special_dates: special_dates)

      result = outcome.result

      expect(result[0]).to eq({
        working_dates: ["2019-05-13", "2019-05-20", "2019-05-27"],
        holiday_dates: ["2019-05-01", "2019-05-02", "2019-05-03", "2019-05-04", "2019-05-05", "2019-05-06"]
      })
      expect(result[1]).to eq(["2019-05-13"])
    end

    context "when booking page got special booking start time" do
      let(:booking_page) { FactoryBot.create(:booking_page, end_at: nil, specific_booking_start_times: ["09:01"]) }

      it "returns expected result, returns all available booking time" do
        special_dates = [
          "{\"start_at_date_part\":\"2019-05-13\",\"start_at_time_part\":\"01:00\",\"end_at_date_part\":\"2019-05-13\",\"end_at_time_part\":\"23:59\"}",
        ]
        args.merge!(special_dates: special_dates)

        result = outcome.result

        expect(result[0]).to eq({
          working_dates: ["2019-05-13", "2019-05-20", "2019-05-27"],
          holiday_dates: ["2019-05-01", "2019-05-02", "2019-05-03", "2019-05-04", "2019-05-05", "2019-05-06"]
        })
        expect(result[1]).to eq(["2019-05-13"])
      end
    end

    context "when special_dates is empty array" do
      it "returns expected result" do
        special_dates = [ ]
        args.merge!(special_dates: special_dates, special_date_type: true)

        result = outcome.result

        expect(result[0]).to eq({
          working_dates: ["2019-05-13", "2019-05-20", "2019-05-27"],
          holiday_dates: ["2019-05-01", "2019-05-02", "2019-05-03", "2019-05-04", "2019-05-05", "2019-05-06"]
        })
        expect(result[1]).to eq([])
      end
    end

    context "when today is 2019-05-13" do
      # Default booking page limit day is 1, that means you couldn't book today
      let(:today) { Time.zone.local(2019, 5, 13) }

      it "returns expected result" do
        special_dates = [
          "{\"start_at_date_part\":\"2019-05-13\",\"start_at_time_part\":\"01:00\",\"end_at_date_part\":\"2019-05-13\",\"end_at_time_part\":\"12:59\"}",
        ]
        args.merge!(special_dates: special_dates)

        result = outcome.result

        expect(result[0]).to eq({
          working_dates: ["2019-05-13", "2019-05-20", "2019-05-27"],
          holiday_dates: ["2019-05-01", "2019-05-02", "2019-05-03", "2019-05-04", "2019-05-05", "2019-05-06"]
        })
        expect(result[1]).to eq([])
      end
    end
  end

  context "when booking option with single menu and one staff could handle the menu" do
    let(:staff) { FactoryBot.create(:staff, :full_time, shop: shop, user: user) }
    let(:booking_option) { FactoryBot.create(:booking_option, :single_menu, user: user) }

    before do
      FactoryBot.create(:staff_menu, menu: booking_option.menus.first, staff: staff)
      FactoryBot.create(:shop_menu, menu: booking_option.menus.first, shop: shop)

      args.merge!(booking_option_ids: [booking_option.id])
    end

    it "returns expected result" do
      result = outcome.result

      expect(result[1]).to eq(["2019-05-13", "2019-05-20", "2019-05-27"])
    end

    # available_booking_start_date
    context "when today is 2019-05-13" do
      # Default booking page limit day is 1, that means you couldn't book today
      let(:today) { Time.zone.local(2019, 5, 13) }

      it "returns expected result" do
        result = outcome.result

        expect(result[1]).to eq(["2019-05-20", "2019-05-27"])
      end
    end

    context 'when calendar date over available_booking_end_date' do
      let(:date_range) { booking_page.available_booking_end_date.tomorrow..booking_page.available_booking_end_date.tomorrow.tomorrow.end_of_month.end_of_day }

      it "returns expected result" do
        result = outcome.result

        expect(result[1]).to eq([])
      end
    end

    context "when booking option only sells during a period" do
      let(:booking_option) { FactoryBot.create(:booking_option, :single_menu, user: user,
                                               start_at: Time.new(2019, 5, 14),
                                               end_at: Time.new(2019, 5, 26)) }

      it "returns expected result" do
        result = outcome.result

        expect(result[1]).to eq(["2019-05-20"])
      end
    end

    context "when staff is not available for some reason" do
      context "staff had reservation on other shop" do
        it "returns expected result" do
          # other_shop error
          expect(Reservable::Reservation).to receive(:run).at_least(3).times.and_call_original
          FactoryBot.create(:reservation,
                            shop: FactoryBot.create(:shop, user: user), staffs: staff,
                            start_time: Time.zone.local(2019, 5, 13, 9),
                            force_end_time: Time.zone.local(2019, 5, 13, 10))
          result = outcome.result

          expect(result[1]).to eq(["2019-05-20", "2019-05-27"])
        end
      end

      context "when staff is a freelancer and doesn't work on that day" do
        # freelancer error
        let(:staff) { FactoryBot.create(:staff, shop: shop, user: user) }

        before do
          FactoryBot.create(:custom_schedule, :opened, shop: shop, staff: staff,
                            start_time: Time.zone.local(2019, 5, 20).beginning_of_day, end_time: Time.zone.local(2019, 5, 20).end_of_day)
          FactoryBot.create(:custom_schedule, :opened, shop: shop, staff: staff,
                            start_time: Time.zone.local(2019, 5, 27).beginning_of_day, end_time: Time.zone.local(2019, 5, 27).end_of_day)
        end

        it "returns expected result" do
          expect(Reservable::Reservation).to receive(:run).at_least(3).times.and_call_original
          result = outcome.result

          expect(result[1]).to eq(["2019-05-20", "2019-05-27"])
        end
      end

      context "when staff ask for leave on that day" do
        # ask_for_leave error
        before do
          schedule = FactoryBot.create(:custom_schedule, :closed, shop: shop, user: staff.staff_account.user,
                            start_time: Time.zone.local(2019, 5, 13).beginning_of_day, end_time: Time.zone.local(2019, 5, 13).end_of_day.change(sec: 0))
          FactoryBot.create(:social_user, user: schedule.user)
        end

        it "returns expected result" do
          expect(Reservable::Reservation).to receive(:run).at_least(3).times.and_call_original
          result = outcome.result

          expect(result[1]).to eq(["2019-05-20", "2019-05-27"])
        end
      end

      context "when staff is a part time staff, doesn't work on that day" do
        # unworking_staff error
        let(:staff) { FactoryBot.create(:staff, user: user, shop: shop) }
        before do
          # Only work in Tuesday
          FactoryBot.create(:business_schedule, :opened, staff: staff, shop: shop,
                            start_time: Time.zone.local(2016, 5, 14, 9, 0, 0),
                            end_time: Time.zone.local(2016, 5, 14, 17, 0, 0))
        end

        it "returns expected result" do
          expect(Reservable::Reservation).to receive(:run).at_least(3).times.and_call_original
          result = outcome.result

          expect(result[1]).to eq([])
        end
      end
    end

    xcontext "when menu is not available at that day" do
      # unschedule_menu
      context "when setting contains day_of_week" do
        before do
          # Menu isn't available on Monday
          booking_option.menus.first.reservation_setting.update_columns(day_type: "weekly", days_of_week: [2, 3, 4, 5])
        end

        it "returns expected result" do
          expect(Reservable::Reservation).to receive(:run).at_least(3).times.and_call_original
          result = outcome.result

          expect(result[1]).to eq([])
        end
      end

      context "when setting contains nth_of_week" do
        before do
          # Menu only available on 1st week
          booking_option.menus.first.reservation_setting.update_columns(day_type: "monthly", nth_of_week: 1)
        end

        it "returns expected result" do
          expect(Reservable::Reservation).to receive(:run).at_least(3).times.and_call_original
          result = outcome.result

          expect(result[1]).to eq([])
        end
      end

      context "when setting contains day" do
        before do
          # Menu only available on day 13
          booking_option.menus.first.reservation_setting.update_columns(day_type: "monthly", day: 13)
        end

        it "returns expected result" do
          expect(Reservable::Reservation).to receive(:run).at_least(3).times.and_call_original
          result = outcome.result

          expect(result[1]).to eq(["2019-05-13"])
        end
      end
    end

    context "when all day are reserved" do
      context "when reservation was fully occupied" do
        it "returns expected result" do
          FactoryBot.create(:reservation, :fully_occupied,
                            menus: booking_option.menus,
                            shop: shop, staffs: staff,
                            start_time: Time.zone.local(2019, 5, 13, 9),
                            force_end_time: Time.zone.local(2019, 5, 13, 17))
          result = outcome.result

          expect(result[1]).to eq(["2019-05-20", "2019-05-27"])
        end
      end

      context "when reservation was not fully occupied(there is space for extra customers)" do
        it "returns expected result" do
          FactoryBot.create(:reservation,
                            menus: booking_option.menus,
                            shop: shop, staffs: staff,
                            start_time: Time.zone.local(2019, 5, 13, 9),
                            force_end_time: Time.zone.local(2019, 5, 13, 17))

          result = outcome.result

          expect(result[1]).to eq(["2019-05-13", "2019-05-20", "2019-05-27"])
        end
      end
    end

    context "when there is existing reservation after this new reservation time" do
      before do
        # The free gap is 9: 00 ~ 10:10
        FactoryBot.create(:reservation, shop: shop, staffs: staff,
                          start_time: Time.zone.local(2019, 5, 13, 10, 10),
                          end_time: Time.zone.local(2019, 5, 13, 17))
      end

      it "returns expected result" do
        result = outcome.result

        expect(result[1]).to eq(["2019-05-13", "2019-05-20", "2019-05-27"])
      end
    end

    context "when there is existing reservation before this new reservation time" do
      # the time gap need booking option required time(60) + interval(10)
      before do
        FactoryBot.create(:reservation, shop: shop, staffs: staff,
                          start_time: Time.zone.local(2019, 5, 13, 9),
                          end_time: Time.zone.local(2019, 5, 13, 15, 50))
        # The free gap is 16: 00 ~ 17:00
      end

      it "returns expected result" do
        result = outcome.result

        expect(result[1]).to eq(["2019-05-13", "2019-05-20", "2019-05-27"])
      end
    end

    context "when there are existing reservations around this new reservation time" do
      # the time gap need booking option required time(60) + interval(10)
      before do
        FactoryBot.create(:reservation, shop: shop, staffs: staff,
                          start_time: Time.zone.local(2019, 5, 13, 9),
                          end_time: Time.zone.local(2019, 5, 13, 10))

        # The free gap is 10: 30 ~ 11:40
        FactoryBot.create(:reservation, shop: shop, staffs: staff,
                          start_time: Time.zone.local(2019, 5, 13, 11, 40),
                          end_time: Time.zone.local(2019, 5, 13, 17))
      end

      it "returns expected result" do
        result = outcome.result

        expect(result[1]).to eq(["2019-05-13", "2019-05-20", "2019-05-27"])
      end
    end
  end

  context "when booking option with coperation menu" do
    context "when NOT enough staffs could handle the menu" do
      before do
        booking_option = FactoryBot.create(:booking_option, :single_coperation_menu, user: user)
        staff = FactoryBot.create(:staff, :full_time, shop: shop, user: user)
        FactoryBot.create(:staff_menu, menu: booking_option.menus.first, staff: staff)
        FactoryBot.create(:shop_menu, menu: booking_option.menus.first, shop: shop)

        args.merge!(booking_option_ids: [booking_option.id])
      end

      it "returns expected result" do
        result = outcome.result

        expect(result[1]).to eq([])
      end
    end

    context "when enough staffs could handle the menu" do
      before do
        booking_option = FactoryBot.create(:booking_option, :single_coperation_menu, user: user)
        staff1 = FactoryBot.create(:staff, :full_time, shop: shop, user: user)
        staff2 = FactoryBot.create(:staff, :full_time, shop: shop, user: user)
        FactoryBot.create(:staff_menu, menu: booking_option.menus.first, staff: staff1)
        FactoryBot.create(:staff_menu, menu: booking_option.menus.first, staff: staff2)
        FactoryBot.create(:shop_menu, menu: booking_option.menus.first, shop: shop)

        args.merge!(booking_option_ids: [booking_option.id])
      end

      it "returns expected result" do
        result = outcome.result

        expect(result[1]).to eq(["2019-05-13", "2019-05-20", "2019-05-27"])
      end
    end
  end

  context "when booking option with multiple menus" do
    context "when all menus are single menu and enough staffs could handle the menu" do
      before do
        booking_option = FactoryBot.create(:booking_option, :multiple_menus, user: user)
        staff = FactoryBot.create(:staff, :full_time, shop: shop, user: user)
        booking_option.menus.each do |menu|
          FactoryBot.create(:staff_menu, menu: menu, staff: staff)
          FactoryBot.create(:shop_menu, menu: menu, shop: shop)
        end

        args.merge!(booking_option_ids: [booking_option.id])
      end

      it "returns expected result" do
        result = outcome.result

        expect(result[1]).to eq(["2019-05-13", "2019-05-20", "2019-05-27"])
      end
    end

    context "when booking_option DON'T need menus be executed in order(menu_restrict_order is false)" do
      context "when all possible menus order are invalid to book" do
        let(:booking_option) { FactoryBot.create(:booking_option, :multiple_menus, menu_restrict_order: false, user: user) }
        let(:staff) { FactoryBot.create(:staff, :full_time, shop: shop, user: user) }

        before do
          booking_option.menus.each do |menu|
            FactoryBot.create(:staff_menu, menu: menu, staff: staff)
            FactoryBot.create(:shop_menu, menu: menu, shop: shop)
          end

          args.merge!(booking_option_ids: [booking_option.id])
        end

        it "returns expected result" do
          # staff was fully booked all day on 5/13 
          FactoryBot.create(:reservation, :fully_occupied,
                            menus: booking_option.menus,
                            shop: shop, staffs: staff,
                            start_time: Time.zone.local(2019, 5, 13, 9),
                            force_end_time: Time.zone.local(2019, 5, 13, 17))

          result = outcome.result

          expect(result[1]).to eq(["2019-05-20", "2019-05-27"])
        end

        it "returns expected result" do
          # staff had reservation on 5/13 but there was left seats
          FactoryBot.create(:reservation,
                            menus: booking_option.menus,
                            shop: shop, staffs: staff,
                            start_time: Time.zone.local(2019, 5, 13, 9),
                            force_end_time: Time.zone.local(2019, 5, 13, 17))

          result = outcome.result

          expect(result[1]).to eq(["2019-05-13", "2019-05-20", "2019-05-27"])
        end

        context "when there is another staff could handle the booking option's menus" do
          it "returns expected result" do
            # staff was fully booked all day on 5/13 
            FactoryBot.create(:reservation, shop: shop, staffs: staff,
                              start_time: Time.zone.local(2019, 5, 13, 9),
                              end_time: Time.zone.local(2019, 5, 13, 17))

            # when staff2 is still available on 5/13
            staff2 = FactoryBot.create(:staff, :full_time, shop: shop, user: user)
            booking_option.menus.each do |menu|
              FactoryBot.create(:staff_menu, menu: menu, staff: staff2)
            end
            result2 = outcome.result
            expect(result2[1]).to eq(["2019-05-13", "2019-05-20", "2019-05-27"])
          end
        end
      end

      context "when any possible menus order are valid to book" do
        let(:booking_option) {
          FactoryBot.create(
            :booking_option,
            user: user,
            menu_restrict_order: false,
            menus: [
              FactoryBot.create(:menu, :with_reservation_setting, user: user, minutes: 120, interval: 20),
              FactoryBot.create(:menu, :with_reservation_setting, user: user, minutes: 90, interval: 20),
              FactoryBot.create(:menu, :with_reservation_setting, :coperation, user: user, minutes: 60, interval: 10)
            ]
          )
        }
        let(:staff1) { FactoryBot.create(:staff, :full_time, shop: shop, user: user) }
        let(:staff2) { FactoryBot.create(:staff, :full_time, shop: shop, user: user) }
        let(:staff3) { FactoryBot.create(:staff, :full_time, shop: shop, user: user) }
        let(:staff4) { FactoryBot.create(:staff, :full_time, shop: shop, user: user) }

        before do
          booking_option.menus.each do |menu|
            FactoryBot.create(:staff_menu, menu: menu, staff: staff1)
            FactoryBot.create(:staff_menu, menu: menu, staff: staff2)
            FactoryBot.create(:staff_menu, menu: menu, staff: staff3)
            FactoryBot.create(:staff_menu, menu: menu, staff: staff4)
            FactoryBot.create(:shop_menu, menu: menu, shop: shop)
          end

          args.merge!(booking_option_ids: [booking_option.id])
        end

        it "returns expected result" do
          # The expects menu order is 60 -> 120 -> 90 minutes' menus
          # when staff1 are available for 75 minute 60 + 15(before reservation),
          # then staff2 are available for 120 minutes 120, middle menu without interval time)
          # then staff3 are available for 105 minutes 90 + 15(after reservation)
          # 15 is booking option interval time
          # free from 9:00 ~ 11:00 for staff1, free all day for staff4,
          # so staff1 and staff 4 take create the 60 minutes coperation menu from 10:00 ~ 11:00
          FactoryBot.create(:reservation, shop: shop, staffs: staff1,
                            start_time: Time.zone.local(2019, 5, 13, 11, 00),
                            end_time: Time.zone.local(2019, 5, 13, 17))
          # free from 11:00 ~ 13:00 for staff2, so staff2 take create the 120 minutes menu from 11:00 ~ 13:00
          FactoryBot.create(:reservation, shop: shop, staffs: staff2,
                            start_time: Time.zone.local(2019, 5, 13, 9, 00),
                            end_time: Time.zone.local(2019, 5, 13, 11, 00))
          FactoryBot.create(:reservation, shop: shop, staffs: staff2,
                            start_time: Time.zone.local(2019, 5, 13, 13, 00),
                            end_time: Time.zone.local(2019, 5, 13, 17))
          # free from 13:00 ~ 14:45 for staff3, so staff2 take create the 90 minutes menu from 13:00 ~ 14:45
          FactoryBot.create(:reservation, shop: shop, staffs: staff3,
                            start_time: Time.zone.local(2019, 5, 13, 9, 00),
                            end_time: Time.zone.local(2019, 5, 13, 13, 00))
          FactoryBot.create(:reservation, shop: shop, staffs: staff3,
                            start_time: Time.zone.local(2019, 5, 13, 14, 45),
                            end_time: Time.zone.local(2019, 5, 13, 17))
          result = outcome.result

          expect(result[1]).to eq(["2019-05-13", "2019-05-20", "2019-05-27"])
        end
      end
    end

    context "when booking_option need menus be executed in priority order(menu_restrict_order is true)" do
      context "when the priority order is valid to book" do
        let(:booking_option) {
          FactoryBot.create(
            :booking_option,
            user: user,
            menu_restrict_order: true,
            menus: [
              FactoryBot.create(:menu, :with_reservation_setting, user: user, minutes: 120, interval: 20),
              FactoryBot.create(:menu, :with_reservation_setting, user: user, minutes: 90, interval: 20),
              FactoryBot.create(:menu, :with_reservation_setting, user: user, minutes: 60, interval: 10)
            ]
          )
        }
        let(:staff1) { FactoryBot.create(:staff, :full_time, shop: shop, user: user) }
        let(:staff2) { FactoryBot.create(:staff, :full_time, shop: shop, user: user) }
        let(:staff3) { FactoryBot.create(:staff, :full_time, shop: shop, user: user) }

        before do
          booking_option.menus.each do |menu|
            FactoryBot.create(:staff_menu, menu: menu, staff: staff1)
            FactoryBot.create(:staff_menu, menu: menu, staff: staff2)
            FactoryBot.create(:staff_menu, menu: menu, staff: staff3)
            FactoryBot.create(:shop_menu, menu: menu, shop: shop)
          end

          args.merge!(booking_option_ids: [booking_option.id])
        end

        it "returns expected result" do
          # The expects menu order is 120 -> 90 -> 60 minutes' menus
          # then staff1 are available for 120 minutes menu, required 120 + 15 minutes
          # then staff2 are available for 90 minutes menu, required 90 minutes
          # when staff3 are available for 75 minute menu, required 60 + 15 minutes,
          # 15 is booking option interval time
          # free from 9:00 ~ 11:00 for staff1, so staff1 take create the 120 minutes menu from 9:00 ~ 11:00
          FactoryBot.create(:reservation, shop: shop, staffs: staff1,
                            start_time: Time.zone.local(2019, 5, 13, 11, 00),
                            end_time: Time.zone.local(2019, 5, 13, 17))
          # free from 11:00 ~ 12:30 for staff2, so staff2 take create the 90 minutes menu from 11:00 ~ 12:30
          FactoryBot.create(:reservation, shop: shop, staffs: staff2,
                            start_time: Time.zone.local(2019, 5, 13, 9, 00),
                            end_time: Time.zone.local(2019, 5, 13, 11, 00))
          FactoryBot.create(:reservation, shop: shop, staffs: staff2,
                            start_time: Time.zone.local(2019, 5, 13, 12, 30),
                            end_time: Time.zone.local(2019, 5, 13, 17))
          # free from 12:30 ~ 13:45 for staff3, so staff3 take create the 60 minutes menu from 12:30 ~ 13:45
          FactoryBot.create(:reservation, shop: shop, staffs: staff3,
                            start_time: Time.zone.local(2019, 5, 13, 9, 00),
                            end_time: Time.zone.local(2019, 5, 13, 12, 30))
          FactoryBot.create(:reservation, shop: shop, staffs: staff3,
                            start_time: Time.zone.local(2019, 5, 13, 13, 45),
                            end_time: Time.zone.local(2019, 5, 13, 17))
          result = outcome.result

          expect(result[1]).to eq(["2019-05-13", "2019-05-20", "2019-05-27"])
        end
      end

      context "when the priority order is NOT valid to book" do
        let(:booking_option) {
          FactoryBot.create(
            :booking_option,
            user: user,
            menu_restrict_order: true,
            menus: [
              FactoryBot.create(:menu, :with_reservation_setting, user: user, minutes: 120, interval: 20),
              FactoryBot.create(:menu, :with_reservation_setting, user: user, minutes: 60, interval: 10)
            ]
          )
        }
        let(:staff1) { FactoryBot.create(:staff, :full_time, shop: shop, user: user) }
        let(:staff2) { FactoryBot.create(:staff, :full_time, shop: shop, user: user) }

        before do
          booking_option.menus.each do |menu|
            FactoryBot.create(:staff_menu, menu: menu, staff: staff1)
            FactoryBot.create(:staff_menu, menu: menu, staff: staff2)
            FactoryBot.create(:shop_menu, menu: menu, shop: shop)
          end

          args.merge!(booking_option_ids: [booking_option.id])
        end

        it "returns expected result" do
          # when staff1 are available for 70 minutes(60 + 15(before reservation)), then staff2 are available for 120 minutes(120 + 15(after reservation))
          # 15 is booking option interval time
          # free from 9:00 ~ 10:00 for staff1, so staff1 take create the 60 minutes menu from 9:00 ~ 10:00
          FactoryBot.create(:reservation, :fully_occupied, shop: shop, staffs: staff1,
                            menus: booking_option.menus,
                            start_time: Time.zone.local(2019, 5, 13, 10, 00),
                            force_end_time: Time.zone.local(2019, 5, 13, 17))
          # free from 10:00 ~ 12:15 for staff2, so staff2 take create the 120 minutes menu from 10:00 ~ 12:15
          FactoryBot.create(:reservation, :fully_occupied, shop: shop, staffs: staff2,
                            menus: booking_option.menus,
                            start_time: Time.zone.local(2019, 5, 13, 9, 00),
                            force_end_time: Time.zone.local(2019, 5, 13, 10, 00))
          FactoryBot.create(:reservation, :fully_occupied, shop: shop, staffs: staff2,
                            menus: booking_option.menus,
                            start_time: Time.zone.local(2019, 5, 13, 12, 15),
                            force_end_time: Time.zone.local(2019, 5, 13, 17))
          # BUT the menu order is restrict, 120 minutes need to be executed first, so no staffs could handle this booking option
          result = outcome.result

          expect(result[1]).to eq(["2019-05-20", "2019-05-27"])
        end
      end
    end

    context "when there is menu is coperation menu and enough staffs could handle the menu" do
      before do
        booking_option = FactoryBot.create(:booking_option, :multiple_coperation_menus, user: user)
        staff1 = FactoryBot.create(:staff, :full_time, shop: shop, user: user)
        staff2 = FactoryBot.create(:staff, :full_time, shop: shop, user: user)
        FactoryBot.create(:staff_menu, menu: booking_option.menus.first, staff: staff1)
        FactoryBot.create(:staff_menu, menu: booking_option.menus.last, staff: staff1)
        FactoryBot.create(:staff_menu, menu: booking_option.menus.last, staff: staff2)
        FactoryBot.create(:shop_menu, menu: booking_option.menus.first, shop: shop)
        FactoryBot.create(:shop_menu, menu: booking_option.menus.last, shop: shop)

        args.merge!(booking_option_ids: [booking_option.id])
      end

      it "returns expected result" do
        result = outcome.result

        expect(result[1]).to eq(["2019-05-13", "2019-05-20", "2019-05-27"])
      end
    end
  end
end
