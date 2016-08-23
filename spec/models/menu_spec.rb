require 'rails_helper'

RSpec.describe Menu, type: :model do
  describe "#valid_max_seat_number" do
    context "min_staffs_number = 1" do
      let(:menu) { FactoryGirl.build(:menu, min_staffs_number: 1, max_seat_number: 1) }

      context "when max_seat_number is not nil" do
        it "is invalid" do
          expect(menu).to be_invalid
        end
      end
    end

    context "min_staffs_number > 1" do
      let(:menu) { FactoryGirl.build(:menu, min_staffs_number: 2, max_seat_number: nil) }

      context "when max_seat_number is nil" do
        it "is invalid" do
          expect(menu).to be_invalid
        end
      end
    end
  end
end
