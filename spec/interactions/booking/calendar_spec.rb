require "rails_helper"

RSpec.describe Booking::Calendar do
  before do
    # Monday
    Timecop.freeze(Time.zone.local(2019, 5, 13))
  end

  let(:business_schedule) { FactoryBot.create(:business_schedule) }
  let(:shop) { business_schedule.shop }
  let(:user) { shop.user }
  let(:date_range) { Date.current.beginning_of_month..Date.current.end_of_month  }
  let(:args) do
    {
      shop: shop,
      date_range: date_range,
    }
  end
  let(:outcome) { described_class.run(args) }

  context "when special_dates exists" do
    it "returns expected result" do
      special_dates = [
        "{\"start_at_date_part\":\"2019-05-06\",\"start_at_time_part\":\"01:00\",\"end_at_date_part\":\"2019-05-06\",\"end_at_time_part\":\"12:59\"}",
      ]
      args.merge!(special_dates: special_dates)

      result = outcome.result

      expect(result[0]).to eq({
        working_dates: ["2019-05-13", "2019-05-20", "2019-05-27"],
        holiday_dates: ["2019-05-03", "2019-05-04", "2019-05-05", "2019-05-06", "2019-05-12", "2019-05-19", "2019-05-26"]
      })
      expect(result[1]).to eq(["2019-05-06"])
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

    context "when booking option only sells during a period" do
      let(:booking_option) { FactoryBot.create(:booking_option, :single_menu, user: user,
                                               start_at_date_part: "2019-05-14", start_at_time_part: "00:00",
                                               end_at_date_part: "2019-05-26", end_at_time_part: "00:00") }

      it "returns expected result" do
        result = outcome.result

        expect(result[1]).to eq(["2019-05-20"])
      end
    end

    context "when all day are reserved" do
      before do
        FactoryBot.create(:reservation, shop: shop, staff_ids: [staff.id],
                          start_time: Time.zone.local(2019, 5, 13, 9),
                          end_time: Time.zone.local(2019, 5, 13, 17))
      end

      it "returns expected result" do
        result = outcome.result

        expect(result[1]).to eq(["2019-05-20", "2019-05-27"])
      end

      context "when the booking option's menu is no-manpower type(min_staffs_number is 0)" do
        let(:menu) { FactoryBot.create(:menu, :with_reservation_setting, :no_manpower, user: user) }
        let(:booking_option) { FactoryBot.create(:booking_option, user: user, menus: [menu]) }

        # The no-manpower menu still need available staff
        it "returns expected result" do
          result = outcome.result

          expect(result[1]).to eq(["2019-05-20", "2019-05-27"])
        end
      end
    end

    context "when there is existing reservation after this new reservation time" do
      before do
        # The free gap is 9: 00 ~ 10:10
        FactoryBot.create(:reservation, shop: shop, staff_ids: [staff.id],
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
        FactoryBot.create(:reservation, shop: shop, staff_ids: [staff.id],
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
        FactoryBot.create(:reservation, shop: shop, staff_ids: [staff.id],
                          start_time: Time.zone.local(2019, 5, 13, 9),
                          end_time: Time.zone.local(2019, 5, 13, 10))

        # The free gap is 10: 30 ~ 11:40
        FactoryBot.create(:reservation, shop: shop, staff_ids: [staff.id],
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
          FactoryBot.create(:reservation, shop: shop, staff_ids: [staff.id],
                            start_time: Time.zone.local(2019, 5, 13, 9),
                            end_time: Time.zone.local(2019, 5, 13, 17))
          result = outcome.result

          expect(result[1]).to eq(["2019-05-20", "2019-05-27"])
        end

        context "when there is another staff could handle the booking option's menus" do
          it "returns expected result" do
            # staff was fully booked all day on 5/13 
            FactoryBot.create(:reservation, shop: shop, staff_ids: [staff.id],
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
            interval: 15,
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
          FactoryBot.create(:reservation, shop: shop, staff_ids: [staff1.id],
                            start_time: Time.zone.local(2019, 5, 13, 10, 00),
                            end_time: Time.zone.local(2019, 5, 13, 17))
          # free from 10:00 ~ 12:15 for staff2, so staff2 take create the 120 minutes menu from 10:00 ~ 12:15
          FactoryBot.create(:reservation, shop: shop, staff_ids: [staff2.id],
                            start_time: Time.zone.local(2019, 5, 13, 9, 00),
                            end_time: Time.zone.local(2019, 5, 13, 10, 00))
          FactoryBot.create(:reservation, shop: shop, staff_ids: [staff2.id],
                            start_time: Time.zone.local(2019, 5, 13, 12, 15),
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
            interval: 15,
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
          # when staff1 are available for 120 minutes(120 + 15(before reservation)), staff2 are available for 70 minutes(60 + 15(after reservation))
          # 15 is booking option interval time
          # free from 9:00 ~ 11:00 for staff1, so staff1 take create the 120 minutes menu from 9:00 ~ 11:00
          FactoryBot.create(:reservation, shop: shop, staff_ids: [staff1.id],
                            start_time: Time.zone.local(2019, 5, 13, 11, 00),
                            end_time: Time.zone.local(2019, 5, 13, 17))
          # free from 11:00 ~ 12:15 for staff2, so staff2 take create the 60 minutes menu from 11:00 ~ 12:15
          FactoryBot.create(:reservation, shop: shop, staff_ids: [staff2.id],
                            start_time: Time.zone.local(2019, 5, 13, 9, 00),
                            end_time: Time.zone.local(2019, 5, 13, 11, 00))
          FactoryBot.create(:reservation, shop: shop, staff_ids: [staff2.id],
                            start_time: Time.zone.local(2019, 5, 13, 12, 15),
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
            interval: 15,
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
          FactoryBot.create(:reservation, shop: shop, staff_ids: [staff1.id],
                            start_time: Time.zone.local(2019, 5, 13, 10, 00),
                            end_time: Time.zone.local(2019, 5, 13, 17))
          # free from 10:00 ~ 12:15 for staff2, so staff2 take create the 120 minutes menu from 10:00 ~ 12:15
          FactoryBot.create(:reservation, shop: shop, staff_ids: [staff2.id],
                            start_time: Time.zone.local(2019, 5, 13, 9, 00),
                            end_time: Time.zone.local(2019, 5, 13, 10, 00))
          FactoryBot.create(:reservation, shop: shop, staff_ids: [staff2.id],
                            start_time: Time.zone.local(2019, 5, 13, 12, 15),
                            end_time: Time.zone.local(2019, 5, 13, 17))
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
