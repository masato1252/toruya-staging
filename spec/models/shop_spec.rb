require 'rails_helper'

RSpec.describe Shop, type: :model do

  # describe "#no_manpower_menus" do
  #   let(:menu) { FactoryBot.create(:menu, user: user, minutes: 60, shop: shop) }
  #   let(:no_manpower_menus) { FactoryBot.create(:menu, :no_manpower, user: user, minutes: 60, shop: shop) }
  #   let(:staff) { FactoryBot.create(:staff, :full_time, user: user, shop: shop) }
  #   before do
  #     FactoryBot.create(:staff_menu, menu: menu, staff: staff)
  #     FactoryBot.create(:staff_menu, menu: no_manpower_menus, staff: staff)
  #   end
  #
  #   context "when even staff already reservation during that time" do
  #     before do
  #       FactoryBot.create(:reservation, shop: shop, menu: menu,
  #                          start_time: time_range.first, end_time: time_range.last, staff_ids: [staff.id])
  #     end
  #
  #     it "still returns no_manpower menus" do
  #       expect(shop.available_reservation_menus(time_range)).to eq(Menu.none)
  #       expect(shop.no_manpower_menus(time_range)).to include(no_manpower_menus)
  #     end
  #   end
  #
  #   context "when staff had custom_schedule during that time" do
  #     let!(:custom_schedule) { FactoryBot.create(:custom_schedule, staff: staff, start_time: time_range.first, end_time: time_range.last) }
  #
  #     it "returns empty" do
  #       expect(shop.no_manpower_menus(time_range)).to eq(Menu.none)
  #     end
  #   end
  # end
end
