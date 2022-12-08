# frozen_string_literal: true

require "rails_helper"

RSpec.describe Reservations::Accept do
  let(:reservation) { FactoryBot.create(:reservation) }
  let(:shop) { reservation.shop }
  let(:current_staff) { reservation.staffs.first }
  let(:args) do
    {
      current_staff: current_staff,
      reservation: reservation
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    context "when current_staff is not reservation'staff" do
      let(:current_staff) { FactoryBot.create(:staff, shop: shop, user: shop.user) }

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
      let(:new_staff) { FactoryBot.create(:staff, shop: shop, user: shop.user) }
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

    context "when staff doesn't have proper working schedule for the reservation" do
      it "creates a temporary working schedule for the reservation" do
        expect {
          outcome
        }.to change {
          current_staff.custom_schedules.opened.where(shop: shop).count
        }.by(1)
      end
    end

    context "when staff had proper working schedule for the reservation" do
      context "when staff is full time" do
        before do
          FactoryBot.create(:business_schedule, :full_time, shop: shop, staff: current_staff)
        end

        it "doesn't creates a temporary working schedule for the reservation" do
          expect {
            outcome
          }.not_to change {
            current_staff.custom_schedules.opened.where(shop: reservation.shop).count
          }
        end
      end

      context "when staff works on that day of week" do
        before do
          FactoryBot.create(:business_schedule, :opened, shop: shop, staff: current_staff,
                            start_time: reservation.start_time.advance(minutes: -1), end_time: reservation.ready_time)
        end

        it "doesn't creates a temporary working schedule for the reservation" do
          expect {
            outcome
          }.not_to change {
            current_staff.custom_schedules.opened.where(shop: reservation.shop).count
          }
        end
      end

      context "when staff have temporary working schedule on that date" do
        before do
          FactoryBot.create(:custom_schedule, :opened, shop: shop, staff: current_staff,
                            start_time: reservation.start_time.advance(minutes: -1), end_time: reservation.ready_time)
        end

        it "doesn't creates a temporary working schedule for the reservation" do
          expect {
            outcome
          }.not_to change {
            current_staff.custom_schedules.opened.where(shop: reservation.shop).count
          }
        end
      end

      context "when there is pending customers" do
        it "customers state to accepted" do
          reservation.reservation_customers.first.pending!

          expect {
            outcome
          }.to change {
            reservation.reservation_customers.first.state
          }.to("accepted")
        end
      end
    end
  end
end
