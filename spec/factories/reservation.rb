require "reservation_menu_time_calculator"

FactoryBot.define do
  factory :reservation do
    association :shop
    start_time { Time.zone.now }
    end_time { start_time.advance(hours: 1) }
    prepare_time { start_time - menus.first.interval.minutes }
    ready_time { end_time + menus.last.interval.minutes }

    transient do
      customers { [ FactoryBot.create(:customer, user: shop.user) ] }
      staffs { [ FactoryBot.create(:staff, user: shop.user) ] }
      menus { [ FactoryBot.create(:menu, user: shop.user) ] }
    end

    trait :pending do
      aasm_state { "pending" }
    end

    trait :reserved do
      aasm_state { "reserved" }
    end

     after(:create) do |reservation, proxy|
       menus_number = Array.wrap(proxy.menus).length

       Array.wrap(proxy.menus).each.with_index do |menu, menu_index|
         FactoryBot.create(:reservation_menu, reservation: reservation, menu: menu, position: menu_index)
         time_result = ReservationMenuTimeCalculator.calculate(reservation, proxy.menus, menu_index)

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
         FactoryBot.create(:reservation_customer, reservation: reservation, customer: customer)
       end


       if Array.wrap(proxy.menus).present?
         reservation.update_columns(end_time: reservation.start_time.advance(minutes: proxy.menus.sum(&:minutes)))
       end

       reservation.update_columns(count_of_customers: reservation.reservation_customers.active.count)
     end
  end
end
