require "rails_helper"

RSpec.describe Booking::AvailableBookingTimes do
  before do
    # Monday
    Timecop.freeze(Time.zone.local(2019, 5, 13))
  end

  let(:business_schedule) { FactoryBot.create(:business_schedule) }
  let(:shop) { business_schedule.shop }
  let(:user) { shop.user }
  let(:staff) { FactoryBot.create(:staff, :full_time, shop: shop, user: user) }
  let(:booking_option) { FactoryBot.create(:booking_option, :single_menu, user: user) }
  let(:booking_option2) { FactoryBot.create(:booking_option, :single_menu, user: user) }
  let(:special_dates) {[
    "{\"start_at_date_part\":\"2019-05-13\",\"start_at_time_part\":\"09:00\",\"end_at_date_part\":\"2019-05-13\",\"end_at_time_part\":\"14:00\"}",
  ]}
  let(:overlap_restriction) { true }
  let(:args) do
    {
      shop: shop,
      special_dates: special_dates,
      booking_option_ids: [booking_option.id, booking_option2.id],
      interval: 60,
      overlap_restriction: overlap_restriction
    }
  end

  before do
    FactoryBot.create(:staff_menu, menu: booking_option.menus.first, staff: staff)
    FactoryBot.create(:shop_menu, menu: booking_option.menus.first, shop: shop)
  end

  let(:outcome) { described_class.run(args) }

  it "returns expected result, returns all available booking time" do
    result = outcome.result

    expect(result.flatten).to eq([
      Time.zone.local(2019, 5, 13, 9),
      Time.zone.local(2019, 5, 13, 10),
      Time.zone.local(2019, 5, 13, 11),
      Time.zone.local(2019, 5, 13, 12),
      Time.zone.local(2019, 5, 13, 13)
    ])
  end

  context "when there is existing reservation" do
    before do
      # The free gap is 9: 00 ~ 10:10
      FactoryBot.create(:reservation, shop: shop, staff_ids: [staff.id],
                        start_time: Time.zone.local(2019, 5, 13, 10, 10),
                        end_time: Time.zone.local(2019, 5, 13, 11))
    end

    it "returns expected result, returns all available booking time" do
      result = outcome.result

      expect(result.flatten).to eq([
        Time.zone.local(2019, 5, 13, 9),
        Time.zone.local(2019, 5, 13, 12),
        Time.zone.local(2019, 5, 13, 13)
      ])
    end

    context "when allow to overlap" do
      let(:overlap_restriction) { false }

      it "returns expected result, returns all available booking time" do
        result = outcome.result

        expect(result.flatten).to eq([
          Time.zone.local(2019, 5, 13, 9),
          Time.zone.local(2019, 5, 13, 10),
          Time.zone.local(2019, 5, 13, 11),
          Time.zone.local(2019, 5, 13, 12),
          Time.zone.local(2019, 5, 13, 13)
        ])
      end
    end

    context "when the booking option's menu is no-manpower type(min_staffs_number is 0)" do
      let(:menu) { FactoryBot.create(:menu, :with_reservation_setting, :no_manpower, user: user) }
      let(:booking_option) { FactoryBot.create(:booking_option, user: user, menus: [menu]) }

      # The no-manpower menu still need available staff
      it "returns expected result, returns all available booking time" do
        result = outcome.result

        expect(result.flatten).to eq([
          Time.zone.local(2019, 5, 13, 9),
          Time.zone.local(2019, 5, 13, 12),
          Time.zone.local(2019, 5, 13, 13)
        ])
      end
    end
  end
end
