require "rails_helper"

RSpec.describe Reservations::Accept do
  let(:reservation) { FactoryBot.create(:reservation) }
  let(:current_staff) { reservation.staffs.first }
  let(:args) do
    {
      current_staff: current_staff,
      reservation: reservation
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    context "when reservation is not acceptable" do
      let(:reservation) { FactoryBot.create(:reservation, :reserved) }

      it "add errors" do
        expect(outcome).to be_invalid
      end
    end

    context "when current_staff is a manager" do
    end

    context "when current_staff is a staff" do
      context "when all reservation's staffs accept the reservation" do
        it "becomes reserved" do
          expect(outcome.result).to be_reserved
        end
      end

      context "when not all reservation's staffs accept the reservation" do
        let(:new_staff) { FactoryBot.create(:staff, shop: reservation.shop, user: reservation.shop.user) }
        before do
          reservation.staffs << new_staff
        end

        it "still be pending" do
          expect(outcome.result).to be_pending
        end
      end
    end
  end
end
