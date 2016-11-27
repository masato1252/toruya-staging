require "rails_helper"

RSpec.describe Reservations::RetrieveAvailableMenus do
  describe "#execute" do
    let(:now) { Time.zone.now }
    let(:time_range) { now..now.advance(minutes: 60) }
    let(:user) { shop.user }
    let(:shop) { FactoryGirl.create(:shop) }
    let(:staff) { FactoryGirl.create(:staff, :full_time, user: user, shop: shop) }
    let!(:menu) { FactoryGirl.create(:menu, :with_reservation_setting, user: user, minutes: 60, shop: shop, staffs: [staff]) }

    context "when some menus don't have categories" do
      it "returns expected result" do
        result = Reservations::RetrieveAvailableMenus.run!(
          shop: shop,
          params: {
            start_time_date_part: time_range.first.to_s(:date),
            start_time_time_part: time_range.first.to_s(:time),
            end_time_time_part: time_range.last.to_s(:time),
          }
        )

        expect(result[:category_menus]).to eq([menu])
        expect(result[:selected_menu]).to eq(menu)
        expect(result[:staffs]).to eq([staff])
        expect(result[:reservation]).to be_nil
      end
    end

    context "when all menus have categories" do
      let!(:category) { FactoryGirl.create(:category, user: user, menus: [menu]) }

      it "returns expected result" do
        result = Reservations::RetrieveAvailableMenus.run!(
          shop: shop,
          params: {
            start_time_date_part: time_range.first.to_s(:date),
            start_time_time_part: time_range.first.to_s(:time),
            end_time_time_part: time_range.last.to_s(:time),
          }
        )

        expect(result[:category_menus]).to eq([{ category: category, menus: [menu] }])
        expect(result[:selected_menu]).to eq(menu)
        expect(result[:staffs]).to eq([staff])
        expect(result[:reservation]).to be_nil
      end
    end

    context "when no manpower menus exists" do
      let!(:no_manpower_menu) { FactoryGirl.create(:menu, :with_reservation_setting, :no_manpower, user: user, minutes: 60, shop: shop, staffs: [staff]) }

      it "returns expected result" do
        result = Reservations::RetrieveAvailableMenus.run!(
          shop: shop,
          params: {
            start_time_date_part: time_range.first.to_s(:date),
            start_time_time_part: time_range.first.to_s(:time),
            end_time_time_part: time_range.last.to_s(:time),
          }
        )

        expect(result[:category_menus]).to eq([ menu, no_manpower_menu ])
        expect(result[:selected_menu]).to eq(menu)
        expect(result[:staffs]).to eq([staff])
        expect(result[:reservation]).to be_nil
      end
    end
  end
end
