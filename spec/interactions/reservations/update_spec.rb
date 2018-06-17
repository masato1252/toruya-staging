require "rails_helper"

RSpec.describe Reservations::Update do
  let(:shop) { FactoryBot.create(:shop) }
  let(:reservation) { FactoryBot.create(:reservation, :pending, shop: shop) }
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
    describe "when update a reservation" do
      context "when state is pending" do
        context "when reservation's staffs change" do
          context "when the modified staff is not the current user staff" do
            let(:by_staff) { FactoryBot.create(:staff, shop: shop, user: shop.user) }

            it "notifies the reservation's staffs except the current user staff" do
              expect(ReservationMailer).to receive(:pending).with(reservation, staff).and_return(double(deliver_later: true))

              result = outcome.result

              expect(result).to be_pending
              expect(result.staff_ids).to eq([staff.id])

              reservation_staff = result.reservation_staffs.first
              expect(reservation_staff).to be_pending
            end
          end

          context "when the modified staff is the current user staff" do
            it "doesn't notifies the reservation's staffs but reservation was accepted" do
              expect(ReservationMailer).not_to receive(:pending)

              outcome

              result = outcome.result

              expect(result).to be_reserved
              expect(result.staff_ids).to eq([staff.id])

              reservation_staff = result.reservation_staffs.reload.first
              expect(reservation_staff).to be_accepted
            end
          end

          context "when some of staffs already accept the reservation" do
            xit "only notifies the reservation's staffs except the current user staff and did accepted one" do
              expect(ReservationMailer).to receive(:pending).with(reservation, staff).and_return(double(deliver_later: true))

              outcome
            end
          end
        end
      end
    end
  end
end
