# frozen_string_literal: true

require "rails_helper"

RSpec.describe Reservations::Save do
  let(:shop) { FactoryBot.create(:shop) }
  let(:user) { shop.user }
  let(:reservation) { shop.reservations.new }
  let(:menu) { FactoryBot.create(:menu, shop: shop, user: user, interval: 5) }
  let(:menu2) { FactoryBot.create(:menu, shop: shop, user: user, interval: 10) }
  let(:menu3) { FactoryBot.create(:menu, shop: shop, user: user, interval: 15) }
  let(:staff) { FactoryBot.create(:staff, shop: shop, user: user) }
  let(:staff2) { FactoryBot.create(:staff, shop: shop, user: user) }
  let(:staff3) { FactoryBot.create(:staff, shop: shop, user: user) }
  let(:customer) { FactoryBot.create(:customer, user: user) }
  let(:by_staff) { staff }
  let(:start_time) { Time.zone.local(2016, 1, 1, 7) }
  # XXX: end time == start time + menus total required time
  let(:end_time) { start_time.advance(minutes: menu_staffs_list.sum { |h| h[:menu_required_time] } ) }
  let(:staff_states) do
    [
      {
        staff_id: staff.id,
        state: "pending"
      }
    ]
  end
  let(:menu_staffs_list) do
    [
      {
        menu_id: menu.id,
        position: 0,
        menu_required_time: menu.minutes,
        menu_interval_time: menu.interval,
        staff_ids: [
          staff_id: staff.id
        ]
      }
    ]
  end
  let(:customers_list) do
    [
      {
        customer_id: customer.id.to_s,
        state: "pending"
      }
    ]
  end
  let(:params) do
    {
      start_time: start_time,
      end_time: end_time,
      menu_staffs_list: menu_staffs_list,
      staff_states: staff_states,
      customers_list: customers_list,
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
  before do
    Timecop.travel(start_time.yesterday)
  end

  describe "#execute" do
    describe "when create a new reservation" do
      context 'when customer was accepted when reservation created' do
        let(:customers_list) do
          [
            {
              customer_id: customer.id.to_s,
              state: "accepted"
            }
          ]
        end

        it "notifies customers" do
          expect(ReservationConfirmationJob).to receive(:perform_later).exactly(customers_list.length).times

          outcome

          expect(user.reload.customer_latest_activity_at).to be_present
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
        let(:staff_states) do
          [
            {
              staff_id: staff.id.to_s,
              state: "pending"
            }
          ]
        end
        let(:menu_staffs_list) do
          [
            {
              menu_id: menu.id,
              position: 0,
              menu_required_time: menu.minutes,
              menu_interval_time: menu.interval,
              staff_ids: [
                staff_id: staff.id.to_s
              ]
            },
            {
              menu_id: menu2.id,
              position: 1,
              menu_required_time: menu2.minutes,
              menu_interval_time: menu2.interval,
              staff_ids: [
                staff_id: staff.id.to_s
              ]
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
          let(:staff_states) do
            [
              {
                staff_id: staff.id.to_s,
                state: "pending"
              },
              {
                staff_id: staff2.id.to_s,
                state: "pending"
              },
              {
                staff_id: staff3.id.to_s,
                state: "pending"
              }
            ]
          end
          let(:menu_staffs_list) do
            [
              {
                menu_id: menu3.id,
                position: 0,
                menu_required_time: menu3.minutes,
                menu_interval_time: menu3.interval,
                staff_ids: [
                  staff_id: staff3.id.to_s,
                ]
              },
              {
                menu_id: menu2.id,
                position: 1,
                menu_required_time: menu2.minutes,
                menu_interval_time: menu2.interval,
                staff_ids: [
                  staff_id: staff2.id.to_s,
                ]
              },
              {
                menu_id: menu.id,
                position: 2,
                menu_required_time: menu.minutes,
                menu_interval_time: menu.interval,
                staff_ids: [
                  staff_id: staff.id.to_s,
                ]
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

      xcontext "when reservation's staff is only current user staff(by_staff_id)" do
        it "reservation staff's state is accepted" do
          result = outcome.result
          expect(result).to be_pending
          expect(result.staff_ids).to eq([staff.id])

          reservation_staff = result.reservation_staffs.reload.first
          expect(reservation_staff).to be_accepted
        end
      end

      context "when reservation's staffs are not only current user staff(by_staff_id)" do
        let(:by_staff) { FactoryBot.create(:staff, shop: shop, user: user) }
        let(:new_reservation) { FactoryBot.create(:reservation, :pending) }

        it "state is pending" do
          expect(outcome.result).to be_pending
          expect(outcome.result.staff_ids).to eq([staff.id])
        end
      end

      context "when all reservation staffs accepted" do
        let(:staff_states) do
          [
            {
              staff_id: staff.id,
              state: "accepted"
            }
          ]
        end
        let(:customers_list) do
          [
            {
              customer_id: customer.id.to_s,
              state: "pending"
            },
            {
              customer_id: FactoryBot.create(:customer, user: user).id,
              state: "canceled"
            }
          ]
        end

        it "reservation state is reserved" do
          expect(ReservationConfirmationJob).to receive(:perform_later).exactly(customers_list.find_all { |c| c[:state] == 'pending' }.length).times

          result = outcome.result
          expect(result).to be_reserved
          expect(result.staff_ids).to eq([staff.id])

          reservation_staff = result.reservation_staffs.reload.first
          expect(reservation_staff).to be_accepted

          first_reservation_customer = result.reservation_customers.order(:id).reload.first
          expect(first_reservation_customer).to be_accepted

          last_reservation_customer = result.reservation_customers.order(:id).reload.last
          expect(last_reservation_customer).to be_canceled
          expect(user.reload.customer_latest_activity_at).to be_present
        end
      end
    end

    context "count_of_customers doesn't contains canceled" do
      let(:customers_list) do
        [
          {
            customer_id: customer.id.to_s,
            state: "pending"
          },
          {
            customer_id: FactoryBot.create(:customer, user: user).id,
            state: "accepted"
          },
          {
            customer_id: FactoryBot.create(:customer, user: user).id,
            state: "canceled"
          }
        ]
      end

      it "updates count_of_customers" do
        result = outcome.result
        expect(result.count_of_customers).to eq(2)
      end
    end

    context "when update a reservation" do
      let!(:old_reservation) { described_class.run!(args) }

      context "when nothing changes" do
        it "notifies no customer" do
          expect(ReservationConfirmationJob).to receive(:perform_later).exactly(0).times
          params[:reservation] = old_reservation.reload

          outcome
        end
      end

      context "when customers change" do
        context 'when customer changes state(pending -> accepted)' do
          it "only notifies existing customers" do
            # create new reservation
            reservation = described_class.run!(args)

            expect(ReservationConfirmationJob).to receive(:perform_later).exactly(1).times
            params[:reservation] = reservation.reload
            params[:customers_list] = [
              {
                customer_id: customer.id.to_s,
                state: "accepted"
              },
            ]
            outcome
          end
        end
      end
    end

    context 'when customer booking from booking page and change start time' do
      let!(:custom_message) { FactoryBot.create(:custom_message, scenario: CustomMessages::Customers::Template::BOOKING_PAGE_CUSTOM_REMINDER , service: booking_page, before_minutes: 10) }
      let(:booking_page) { FactoryBot.create(:booking_page, user: user, use_shop_default_message: false) }
      let!(:reservation_customer) { FactoryBot.create(:reservation_customer, booking_page: booking_page) }
      let(:reservation) { reservation_customer.reservation }
      let(:customers_list) do
        [
          {
            customer_id: reservation_customer.customer_id.to_s,
            state: "pending",
            booking_page_id: booking_page.id
          }
        ]
      end
      let(:start_time) { Time.current.tomorrow }

      it 'reschedule reminder message' do
        expect(Notifiers::Customers::CustomMessages::ReservationReminder).to receive(:perform_at) do |args|
          expect(args[:schedule_at].round).to eq(reservation.start_time.advance(minutes: -10).round)
        end

        outcome
      end
    end
    context 'when user booking for customer manually and change start time' do
      let!(:custom_message) { FactoryBot.create(:custom_message, scenario: CustomMessages::Customers::Template::SHOP_CUSTOM_REMINDER , service: shop, before_minutes: 10) }
      let(:customers_list) do
        [
          {
            customer_id: customer.id.to_s,
            state: "pending",
          }
        ]
      end
      let(:start_time) { Time.current.tomorrow }

      it 'reschedule reminder message' do
        expect(Notifiers::Customers::CustomMessages::ReservationReminder).to receive(:perform_at) do |args|
          expect(args[:schedule_at].round).to eq(start_time.advance(minutes: -10).round)
        end

        outcome
      end
    end
  end
end