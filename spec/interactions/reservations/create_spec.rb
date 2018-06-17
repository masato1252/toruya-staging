require "rails_helper"

RSpec.describe Reservations::Create do
  let(:shop) { FactoryBot.create(:shop) }
  let(:reservation) { nil }
  let(:menu) { FactoryBot.create(:menu, shop: shop, user: shop.user) }
  let(:staff) { FactoryBot.create(:staff, shop: shop, user: shop.user) }
  let(:customer) { FactoryBot.create(:customer, user: shop.user) }
  let(:by_staff) { staff }
  let(:params) do
    {
      start_time_date_part: "2016-01-01",
      start_time_time_part: "07:00",
      end_time_time_part: "17:00",
      menu_id: menu.id,
      staff_ids: staff.id.to_s,
      customer_ids: customer.id.to_s,
      with_warnings: false,
      by_staff_id: by_staff.id.to_s
    }
  end
  let(:args) do
    {
      shop: shop,
      reservation: reservation,
      params: params
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    describe "when create a new reservation" do
      context "when reservation's staff is only current user staff(by_staff_id)" do
        it "state is reserved" do
          result = outcome.result
          expect(result).to be_reserved
          expect(result.staff_ids).to eq([staff.id])

          reservation_staff = result.reservation_staffs.reload.first
          expect(reservation_staff).to be_accepted
        end
      end

      context "when reservation's staffs are not only current user staff(by_staff_id)" do
        let(:by_staff) { FactoryBot.create(:staff, shop: shop, user: shop.user) }
        let(:new_reseravtion) { FactoryBot.create(:reservation, :pending) }

        it "state is pending" do
          expect(outcome.result).to be_pending
          expect(outcome.result.staff_ids).to eq([staff.id])
        end

        it "notifies the reservation's staffs except the current user staff" do
          allow(shop.reservations).to receive(:new).with(params).and_return(new_reseravtion)
          expect(ReservationMailer).to receive(:pending).with(new_reseravtion, staff).and_return(double(deliver_later: true))

          outcome
        end
      end
    end
  end
end
