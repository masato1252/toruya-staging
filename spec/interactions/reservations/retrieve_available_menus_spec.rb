# frozen_string_literal: true

require "rails_helper"

RSpec.describe Reservations::RetrieveAvailableMenus do
  describe "#execute" do
    let(:now) { Time.local(2016, 11, 9, 9)}
    let(:time_range) { now..(now.advance(minutes: 60)) }
    let(:user) { shop.user }
    let(:shop) { FactoryBot.create(:shop) }
    let(:staff) { FactoryBot.create(:staff, :full_time, user: user, shop: shop) }
    let!(:menu) { FactoryBot.create(:menu, :with_reservation_setting, user: user, minutes: 60, shop: shop, staffs: [staff]) }

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

        expect(result[:category_menu_options].map(&:id)).to eq([menu.id])
        expect(result[:selected_menu_option].id).to eq(menu.id)
        expect(result[:staff_options].map(&:id)).to eq([staff.id])
        expect(result[:reservation]).to be_nil
      end
    end

    context "when all menus have categories" do
      let!(:category) { FactoryBot.create(:category, user: user, menus: [menu]) }

      it "returns expected result" do
        result = Reservations::RetrieveAvailableMenus.run!(
          shop: shop,
          params: {
            start_time_date_part: time_range.first.to_s(:date),
            start_time_time_part: time_range.first.to_s(:time),
            end_time_time_part: time_range.last.to_s(:time),
          }
        )

        expect(result[:category_menu_options].first[:category]).to eq(category)
        expect(result[:category_menu_options].first[:menu_options].map(&:id)).to eq([menu.id])
        expect(result[:selected_menu_option].id).to eq(menu.id)
        expect(result[:staff_options].map(&:id)).to eq([staff.id])
        expect(result[:reservation]).to be_nil
      end
    end

    context "when no manpower menus exists" do
      let!(:no_manpower_menu) { FactoryBot.create(:menu, :with_reservation_setting, :no_manpower, user: user, minutes: 60, shop: shop, staffs: [staff]) }

      it "returns expected result" do
        result = Reservations::RetrieveAvailableMenus.run!(
          shop: shop,
          params: {
            start_time_date_part: time_range.first.to_s(:date),
            start_time_time_part: time_range.first.to_s(:time),
            end_time_time_part: time_range.last.to_s(:time),
          }
        )

        expect(result[:category_menu_options].map(&:id)).to eq([ menu.id, no_manpower_menu.id ])
        expect(result[:selected_menu_option].id).to eq(menu.id)
        expect(result[:staff_options].map(&:id)).to eq([staff.id])
        expect(result[:reservation]).to be_nil
      end
    end
  end
end
