require "rails_helper"

RSpec.describe Booking::Calendar do
  before do
    # Monday
    Timecop.freeze(Time.zone.local(2019, 5, 10))
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

    before do
      booking_option = FactoryBot.create(:booking_option, :single_menu, user: user)
      FactoryBot.create(:staff_menu, menu: booking_option.menus.first, staff: staff)
      FactoryBot.create(:shop_menu, menu: booking_option.menus.first, shop: shop)

      args.merge!(booking_option_ids: [booking_option.id])
    end

    it "returns expected result" do
      result = outcome.result

      expect(result[1]).to eq(["2019-05-13", "2019-05-20", "2019-05-27"])
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
        FactoryBot.create(:staff_menu, menu: booking_option.menus.first, staff: staff)
        FactoryBot.create(:staff_menu, menu: booking_option.menus.last, staff: staff)
        FactoryBot.create(:shop_menu, menu: booking_option.menus.first, shop: shop)
        FactoryBot.create(:shop_menu, menu: booking_option.menus.last, shop: shop)

        args.merge!(booking_option_ids: [booking_option.id])
      end

      it "returns expected result" do
        result = outcome.result

        expect(result[1]).to eq(["2019-05-13", "2019-05-20", "2019-05-27"])
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
