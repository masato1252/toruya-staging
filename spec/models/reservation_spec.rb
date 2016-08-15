require 'rails_helper'

RSpec.describe Reservation, type: :model do
  let(:shop) { FactoryGirl.create(:shop) }
  let(:reservation) { FactoryGirl.build(:reservation, shop: shop) }
  let(:staff) { FactoryGirl.create(:staff, shop: shop) }
  let(:customer) { FactoryGirl.create(:customer, shop: shop) }
  let(:now) { Time.now }

  describe "#duplicate_staff_or_customer" do
    context "when there are no duplicated staffs or customers during reservation time" do
      it "is valid" do
        expect(reservation).to be_valid
      end
    end

    context "when there are duplicated staffs during reservation time" do
      before do
        FactoryGirl.create(:reservation, shop: shop, staff_ids: [staff.id],
                                         start_time: now, end_time: now.advance(hours: 2))
      end

      # new reservation start time  -> old reservation start time -> new reservation end_time
      context "when old reservation start time is between new reservation start time and end time" do
        let(:reservation) do
          FactoryGirl.build(:reservation, shop: shop, staff_ids: [staff.id],
                            start_time: now.advance(hours: 1), end_time: now.advance(hours: 2) )
        end

        it "is invalid" do
          expect(reservation).to be_invalid
        end
      end

      # new reservation start time  -> old reservation end time -> new reservation end_time
      context "when old reservation end time time is between new reservation start time and end time" do
        let(:reservation) do
          FactoryGirl.build(:reservation, shop: shop, staff_ids: [staff.id],
                            start_time: now, end_time: now.advance(hours: 1) )
        end

        it "is invalid" do
          expect(reservation).to be_invalid
        end
      end

      # old reservation start time -> new reservation start time  -> new reservation end_time -> old reservation end time
      context "when old start time is ealier than new start time and old end time is later than new end time" do
        let(:reservation) do
          FactoryGirl.build(:reservation, shop: shop, staff_ids: [staff.id],
                            start_time: now.advance(hours: -1), end_time: now.advance(hours: 3) )
        end

        it "is invalid" do
          expect(reservation).to be_invalid
        end
      end
    end

    context "when there are duplicated customers during reservation time" do
      let(:reservation) { FactoryGirl.build(:reservation, shop: shop, customer_ids: [customer.id]) }
      before { FactoryGirl.create(:reservation, shop: shop, customer_ids: [customer.id] ) }

      it "is invalid" do
        expect(reservation).to be_invalid
      end
    end
  end
end
