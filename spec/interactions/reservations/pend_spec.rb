# frozen_string_literal: true

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
    it "resets reservation and staff's states to pending" do
      result = outcome.result

      expect(result).to be_pending
      expect(result.reservation_staffs.first).to be_pending
    end
  end
end
