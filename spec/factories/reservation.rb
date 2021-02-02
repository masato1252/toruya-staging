# frozen_string_literal: true

require "reservation_menu_time_calculator"

FactoryBot.define do
  factory :reservation do
    association :shop
    user { shop.user }
    start_time { Time.zone.now }
    end_time { start_time.advance(hours: 1) }
    prepare_time { start_time - menus.first.interval.minutes }
    ready_time { end_time + menus.last.interval.minutes }

    transient do
      customers { [ FactoryBot.create(:customer, user: shop.user) ] }
      staffs { [ FactoryBot.create(:staff, user: shop.user) ] }
      menus { [ FactoryBot.create(:menu, user: shop.user) ] }
      force_end_time {}
    end

    trait :pending do
      aasm_state { "pending" }
    end

    trait :reserved do
      aasm_state { "reserved" }
    end

    trait :fully_occupied do
      customers do
        [
          FactoryBot.create(:customer, user: shop.user),
          FactoryBot.create(:customer, user: shop.user),
          FactoryBot.create(:customer, user: shop.user),
        ]
      end
    end

    after(:create) do |reservation, proxy|
      menus_number = Array.wrap(proxy.menus).length

      if proxy.force_end_time && proxy.menus.length
        required_time = (proxy.force_end_time - reservation.start_time)/60.0

        proxy.menus.last.update(minutes: required_time - proxy.menus[0...-1].sum(&:minutes))

        proxy.menus.each do |menu|
          BookingOptionMenu.where(menu: menu).update_all(required_time: menu.minutes)
        end
      end

      if Array.wrap(proxy.menus).present?
        end_at = reservation.start_time.advance(minutes: proxy.menus.sum(&:minutes))

        reservation.update_columns(
          end_time: end_at,
          ready_time: end_at + proxy.menus.last.interval.minutes
        )
      end

      Array.wrap(proxy.menus).each.with_index do |menu, menu_index|
        FactoryBot.create(:reservation_menu, reservation: reservation, menu: menu, position: menu_index)
        time_result = ReservationMenuTimeCalculator.calculate(reservation, reservation.reservation_menus.reload, menu_index)

        Array.wrap(proxy.staffs).each do |staff|
          unless StaffMenu.where(staff: staff, menu: menu).exists?
            FactoryBot.create(:staff_menu, staff: staff, menu: menu)
          end

          FactoryBot.create(
            :reservation_staff,
            reservation: reservation,
            staff: staff,
            menu: menu,
            prepare_time: time_result[:prepare_time],
            work_start_at: time_result[:work_start_at],
            work_end_at: time_result[:work_end_at],
            ready_time: time_result[:ready_time]
          )
        end
      end

      Array.wrap(proxy.customers).each do |customer|
        FactoryBot.create(:reservation_customer, :accepted, reservation: reservation, customer: customer)
      end

      reservation.update_columns(count_of_customers: reservation.reservation_customers.active.count)
    end
  end
end
