# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Reservation, type: :model do
  let(:user) { shop.user }
  let(:shop) { FactoryBot.create(:shop) }
  let(:menu) { FactoryBot.create(:menu, shop: shop) }
  let(:reservation) { FactoryBot.build(:reservation, menu: menu, shop: shop) }
  let(:staff) { FactoryBot.create(:staff, shop: shop) }
  let(:customer) { FactoryBot.create(:customer, user: user ) }
  let(:now) { Time.now }

  # describe "#duplicate_staff_or_customer" do
  #   before do
  #     FactoryBot.create(:staff_menu, staff: staff, menu: menu)
  #     allow(reservation).to receive(:enough_staffs_for_customers)
  #   end
  #
  #   context "when there are no duplicated staffs or customers during reservation time" do
  #     it "is valid" do
  #       expect(reservation).to be_valid
  #     end
  #   end
  #
  #   context "when there are duplicated staffs during reservation time" do
  #     before do
  #       FactoryBot.create(:reservation, shop: shop, menu: menu, staff_ids: [staff.id],
  #                                        start_time: now, end_time: now.advance(hours: 2))
  #     end
  #
  #     # new reservation start time  -> old reservation start time -> new reservation end_time
  #     context "when old reservation start time is between new reservation start time and end time" do
  #       let(:reservation) do
  #         FactoryBot.build(:reservation, shop: shop, menu: menu, staff_ids: [staff.id],
  #                           start_time: now.advance(hours: 1), end_time: now.advance(hours: 2) )
  #       end
  #
  #       it "is invalid" do
  #         expect(reservation).to be_invalid
  #       end
  #     end
  #
  #     # new reservation start time  -> old reservation end time -> new reservation end_time
  #     context "when old reservation end time time is between new reservation start time and end time" do
  #       let(:reservation) do
  #         FactoryBot.build(:reservation, shop: shop, menu: menu, staff_ids: [staff.id],
  #                           start_time: now, end_time: now.advance(hours: 1) )
  #       end
  #
  #       it "is invalid" do
  #         expect(reservation).to be_invalid
  #       end
  #     end
  #
  #     # old reservation start time -> new reservation start time  -> new reservation end_time -> old reservation end time
  #     context "when old start time is ealier than new start time and old end time is later than new end time" do
  #       let(:reservation) do
  #         FactoryBot.build(:reservation, shop: shop, menu: menu, staff_ids: [staff.id],
  #                           start_time: now.advance(hours: -1), end_time: now.advance(hours: 3) )
  #       end
  #
  #       it "is invalid" do
  #         expect(reservation).to be_invalid
  #       end
  #     end
  #   end
  #
  #   context "when there are duplicated customers during reservation time" do
  #     let(:reservation) { FactoryBot.build(:reservation, shop: shop, menu: menu, customer_ids: [customer.id]) }
  #     before { FactoryBot.create(:reservation, shop: shop, menu: menu, staff_ids: [staff.id], customer_ids: [customer.id] ) }
  #
  #     it "is invalid" do
  #       expect(reservation).to be_invalid
  #     end
  #   end
  # end

  # describe "#enough_staffs_for_customers" do
  #   let(:menu) { FactoryBot.create(:menu, min_staffs_number: 1) }
  #   let(:lecture_menu) { FactoryBot.create(:menu, :lecture, min_staffs_number: 2, max_seat_number: 2, shop: shop) }
  #   let(:staff) { FactoryBot.create(:staff) }
  #   let(:staff2) { FactoryBot.create(:staff) }
  #   let(:customer1) { FactoryBot.create(:customer) }
  #   let(:customer2) { FactoryBot.create(:customer) }
  #   let(:customer3) { FactoryBot.create(:customer) }
  #
  #   context "when staffs number is not enough of menu" do
  #     let(:reservation) { FactoryBot.build(:reservation, menu: lecture_menu, staffs: [staff], shop: shop) }
  #
  #     it "is invalid" do
  #       expect(reservation).to be_invalid
  #       expect(reservation.errors[:base]).to be_include("Not enough staffs for menu")
  #     end
  #   end
  #
  #   context "when menu min_staffs_number is 1" do
  #     before do
  #       FactoryBot.create(:staff_menu, menu: menu, staff: staff, max_customers: 1)
  #     end
  #
  #     context "staff's max_customers total >= customers number" do
  #       let(:reservation) { FactoryBot.build(:reservation, menu: menu, staffs: [staff], customers: [customer1]) }
  #
  #       it "is valid" do
  #         expect(reservation).to be_valid
  #       end
  #     end
  #
  #     context "staff's max_customers total < customers number" do
  #       let(:reservation) { FactoryBot.build(:reservation, menu: menu, staffs: [staff], customers: [customer1, customer2]) }
  #
  #       it "is invalid" do
  #         expect(reservation).to be_invalid
  #         expect(reservation.errors[:base]).to be_include("Not enough staffs for customers")
  #       end
  #     end
  #   end
  #
  #   context "when menu min_staffs_number > 1" do
  #     before do
  #       FactoryBot.create(:staff_menu, menu: lecture_menu, staff: staff)
  #       FactoryBot.create(:staff_menu, menu: lecture_menu, staff: staff2)
  #     end
  #
  #     context "menu max_seat_number >= customers number" do
  #       let(:reservation) { FactoryBot.build(:reservation, menu: lecture_menu, staffs: [staff, staff2], customers: [customer1, customer2], shop: shop) }
  #
  #       it "is valid" do
  #         expect(reservation).to be_valid
  #       end
  #     end
  #
  #     context "menu max_seat_number < customers number" do
  #       let(:reservation) { FactoryBot.build(:reservation, menu: lecture_menu, staffs: [staff, staff2], customers: [customer1, customer2, customer3], shop: shop) }
  #
  #       it "is invalid" do
  #         expect(reservation).to be_invalid
  #         expect(reservation.errors[:base]).to be_include("Not enough seat for customers")
  #       end
  #     end
  #   end
  # end
end
