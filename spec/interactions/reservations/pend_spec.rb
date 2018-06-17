require "rails_helper"

RSpec.describe Reservations::Pend do
  let(:reservation) { FactoryBot.create(:reservation, :reserved) }
  let(:current_staff) { reservation.staffs.first }
  let(:new_staff) { FactoryBot.create(:staff, shop: reservation.shop, user: reservation.shop.user) }
  let(:args) do
    {
      current_staff: current_staff,
      reservation: reservation
    }
  end

  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    context "when reservation could not become pending" do
      let(:reservation) { FactoryBot.create(:reservation, :pending) }

      it "add errors" do
        expect(outcome).to be_invalid
      end
    end

    it "resets reservation and staff's states to pending" do
      result = outcome.result

      expect(result).to be_pending
      expect(result.by_staff).to eq(current_staff)
      expect(result.reservation_staffs.first).to be_pending
    end

    it "notify all the reservation's staffs except the current_staff" do
      reservation.staffs << new_staff
      expect(ReservationMailer).to receive(:pending).with(reservation, new_staff).and_return(double(deliver_later: true)).once
      expect(ReservationMailer).not_to receive(:pending).with(reservation, current_staff)

      outcome
    end
  end
end
