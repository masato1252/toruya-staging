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
        expect(outcome.errors.details[:reservation]).to include(error: :not_acceptable)
      end
    end

    context "when current_staff is not reservation'staff" do
      let(:current_staff) { FactoryBot.create(:staff, shop: reservation.shop, user: reservation.shop.user) }

      it "add errors" do
        expect(outcome.errors.details[:current_staff]).to include(error: :who_r_u)
      end
    end

    context "when all reservation's staffs accept the reservation" do
      it "becomes reserved" do
        result = outcome.result.reload

        expect(result).to be_reserved
        expect(result.for_staff(current_staff)).to be_accepted
      end
    end

    context "when not all reservation's staffs accept the reservation" do
      let(:new_staff) { FactoryBot.create(:staff, shop: reservation.shop, user: reservation.shop.user) }
      before do
        reservation.staffs << new_staff
      end

      it "still be pending" do
        result = outcome.result.reload

        expect(result).to be_pending
        expect(result.for_staff(current_staff)).to be_accepted
        expect(result.for_staff(new_staff)).to be_pending
      end
    end
  end
end
