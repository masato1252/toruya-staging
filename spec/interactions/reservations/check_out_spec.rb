# frozen_string_literal: true

require "rails_helper"

RSpec.describe Reservations::CheckOut do
  let(:customer) { FactoryBot.create(:customer) }
  let(:reservation) { FactoryBot.create(:reservation, :checked_in) }
  let(:args) do
    {
      reservation: reservation
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    context "when reservation is not check_out" do
      let(:reservation) { FactoryBot.create(:reservation, :reserved) }

      it "add errors" do
        expect(outcome.errors.details[:reservation]).to include(error: :not_checkoutable)
      end
    end


    it "checks out reservation" do
      outcome

      expect(reservation).to be_checked_out
    end
  end
end
