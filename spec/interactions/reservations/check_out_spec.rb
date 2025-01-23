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
      let(:reservation) { FactoryBot.create(:reservation, :pending) }

      it "add errors" do
        expect(outcome.errors.details[:reservation]).to include(error: :not_checkoutable)
      end
    end


    it "checks out reservation" do
      outcome

      expect(reservation).to be_checked_out
    end

    context "when there are customers" do
      let(:reservation) { FactoryBot.create(:reservation, :checked_in, customers: [customer]) }
      it "checks out reservation and update customer's menu_ids" do
        outcome

        expect(reservation).to be_checked_out
        expect(customer.reload.menu_ids).to eq(reservation.menu_ids.map(&:to_s))
      end
    end
  end
end
