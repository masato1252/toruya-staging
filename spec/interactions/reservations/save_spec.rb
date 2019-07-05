require "rails_helper"

RSpec.describe Reservations::Save do
  let(:shop) { FactoryBot.create(:shop) }
  let(:reservation) { shop.reservations.new }
  let(:menu) { FactoryBot.create(:menu, shop: shop, user: shop.user, interval: 5) }
  let(:menu2) { FactoryBot.create(:menu, shop: shop, user: shop.user, interval: 10) }
  let(:menu3) { FactoryBot.create(:menu, shop: shop, user: shop.user, interval: 15) }
  let(:staff) { FactoryBot.create(:staff, shop: shop, user: shop.user) }
  let(:staff2) { FactoryBot.create(:staff, shop: shop, user: shop.user) }
  let(:staff3) { FactoryBot.create(:staff, shop: shop, user: shop.user) }
  let(:customer) { FactoryBot.create(:customer, user: shop.user) }
  let(:by_staff) { staff }
  let(:start_time) { Time.zone.local(2016, 1, 1, 7) }
  # XXX: end time == start time + menus total required time
  let(:end_time) { start_time.advance(minutes: menu_staffs_list.map { |list| list.slice(:menu_id, :menu_required_time) }.uniq.sum { |h| h[:menu_required_time] } ) }
  let(:menu_staffs_list) do
    [
      {
        menu_id: menu.id,
        position: 0,
        state: "pending",
        staff_id: staff.id,
        menu_required_time: menu.minutes,
        menu_interval_time: menu.interval
      }
    ]
  end
  let(:params) do
    {
      start_time: start_time,
      end_time: end_time,
      menu_staffs_list: menu_staffs_list,
      customers_list: [
        {
          customer_id: customer.id.to_s,
          state: "pending"
        }
      ],
      with_warnings: false,
      by_staff_id: by_staff.id.to_s
    }
  end
  let(:args) do
    {
      reservation: reservation,
      params: params
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    describe "when create a new reservation" do
      context "when reservation had booking_option" do
        it "uses booking_option's interval time" do
          booking_option = FactoryBot.create(:booking_option, user: shop.user, interval: 15)
          booking_page = FactoryBot.create(:booking_page, user: shop.user)

          params[:booking_option_id] = booking_option.id
          params[:customers_list] = [
            {
              customer_id: customer.id,
              state: "pending",
              booking_option_id: booking_option.id,
              booking_page_id: booking_page.id
            }
          ]

          result = outcome.result

          reservation_staff = result.reservation_staffs.first
          expect(result.prepare_time).to eq(start_time - booking_option.interval.minutes)
          expect(reservation_staff.prepare_time).to eq(result.prepare_time)
          expect(reservation_staff.work_start_at).to eq(result.start_time)
          expect(reservation_staff.work_end_at).to eq(result.end_time)
          expect(reservation_staff.ready_time).to eq(result.ready_time)
          expect(result.ready_time).to eq(end_time + booking_option.interval.minutes)

          reservation_customer = result.reservation_customers.first
          expect(reservation_customer.customer_id).to eq(customer.id)
          expect(reservation_customer.booking_page_id).to eq(booking_page.id)
          expect(reservation_customer.booking_option_id).to eq(booking_option.id)
        end
      end

      context "when there is only one menu" do
        it "staff's prepare time, work times and ready_time would be equal to reservation" do
          result = outcome.result

          reservation_staff = result.reservation_staffs.first
          expect(reservation_staff.prepare_time).to eq(result.prepare_time)
          expect(reservation_staff.work_start_at).to eq(result.start_time)
          expect(reservation_staff.work_end_at).to eq(result.end_time)
          expect(reservation_staff.ready_time).to eq(result.ready_time)

          reservation_menu = result.reservation_menus.first
          expect(reservation_menu.menu_id).to eq(menu.id)
          expect(reservation_menu.position).to eq(0)
        end
      end

      context "when there are multiple menus" do
        let(:menu_staffs_list) do
          [
            {
              menu_id: menu.id,
              position: 0,
              state: "pending",
              staff_id: staff.id.to_s,
              menu_required_time: menu.minutes,
              menu_interval_time: menu.interval
            },
            {
              menu_id: menu2.id,
              position: 1,
              state: "pending",
              staff_id: staff.id.to_s,
              menu_required_time: menu2.minutes,
              menu_interval_time: menu2.interval
            }
          ]
        end

        it "staff's prepare time, work times and ready_time need to be set separately and the menus should be in position order" do
          result = outcome.result

          reservation_staff = result.reservation_staffs.first
          reservation_staff = result.reservation_staffs.order_by_menu_position.first
          expect(reservation_staff.prepare_time).to eq(result.prepare_time)
          expect(reservation_staff.prepare_time).to eq(start_time.advance(minutes: -menu.interval))
          expect(reservation_staff.work_start_at).to eq(start_time)
          expect(reservation_staff.work_end_at).to eq(start_time.advance(minutes: menu.minutes))
          expect(reservation_staff.ready_time).to eq(reservation_staff.work_end_at)
          expect(reservation_staff.staff).to eq(staff)

          second_reservation_staff = result.reservation_staffs.order_by_menu_position.second
          expect(second_reservation_staff.prepare_time).to eq(reservation_staff.work_end_at)
          expect(second_reservation_staff.work_start_at).to eq(reservation_staff.work_end_at)
          expect(second_reservation_staff.work_end_at).to eq(second_reservation_staff.work_start_at.advance(minutes: menu2.minutes))
          expect(second_reservation_staff.ready_time).to eq(result.ready_time)
          expect(second_reservation_staff.ready_time).to eq(second_reservation_staff.work_end_at.advance(minutes: menu2.interval))
          expect(second_reservation_staff.staff).to eq(staff)

          expect(result.menu_ids).to eq([menu.id, menu2.id])
        end

        context "when there are three menus responsible by three staffs" do
          let(:menu_staffs_list) do
            [
              {
                menu_id: menu3.id,
                position: 0,
                state: "pending",
                staff_id: staff3.id.to_s,
                menu_required_time: menu3.minutes,
                menu_interval_time: menu3.interval,
              },
              {
                menu_id: menu2.id,
                position: 1,
                state: "pending",
                staff_id: staff2.id.to_s,
                menu_required_time: menu2.minutes,
                menu_interval_time: menu2.interval,
              },
              {
                menu_id: menu.id,
                position: 2,
                state: "pending",
                staff_id: staff.id.to_s,
                menu_required_time: menu.minutes,
                menu_interval_time: menu.interval,
              }
            ]
          end

          it "the first and last staff need to take care interval time, the middle staff doesn't" do
            result = outcome.result

            reservation_staff = result.reservation_staffs.order_by_menu_position.first
            expect(reservation_staff.prepare_time).to eq(result.prepare_time)
            expect(reservation_staff.prepare_time).to eq(start_time.advance(minutes: -menu3.interval))
            expect(reservation_staff.work_start_at).to eq(start_time)
            expect(reservation_staff.work_end_at).to eq(start_time.advance(minutes: menu3.minutes))
            expect(reservation_staff.ready_time).to eq(reservation_staff.work_end_at)
            expect(reservation_staff.staff).to eq(staff3)

            second_reservation_staff = result.reservation_staffs.order_by_menu_position.second
            expect(second_reservation_staff.prepare_time).to eq(reservation_staff.work_end_at)
            expect(second_reservation_staff.work_start_at).to eq(reservation_staff.work_end_at)
            expect(second_reservation_staff.work_end_at).to eq(second_reservation_staff.work_start_at.advance(minutes: menu2.minutes))
            expect(second_reservation_staff.ready_time).to eq(second_reservation_staff.work_end_at)
            expect(second_reservation_staff.staff).to eq(staff2)

            third_reservation_staff = result.reservation_staffs.order_by_menu_position.third
            expect(third_reservation_staff.prepare_time).to eq(second_reservation_staff.work_end_at)
            expect(third_reservation_staff.work_start_at).to eq(second_reservation_staff.work_end_at)
            expect(third_reservation_staff.work_end_at).to eq(third_reservation_staff.work_start_at.advance(minutes: menu.minutes))
            expect(third_reservation_staff.ready_time).to eq(result.ready_time)
            expect(third_reservation_staff.ready_time).to eq(third_reservation_staff.work_end_at.advance(minutes: menu.interval))
            expect(third_reservation_staff.staff).to eq(staff)

            expect(result.menu_ids).to eq([menu3.id, menu2.id, menu.id])
          end
        end
      end

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
      end
    end
  end
end
