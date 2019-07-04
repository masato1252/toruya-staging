FactoryBot.define do
  factory :reservation do
    association :shop
    start_time { Time.zone.now }
    end_time { start_time.advance(hours: 1) }
    prepare_time { start_time - menus.first.interval.minutes }
    ready_time { end_time - menus.last.interval.minutes }

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
       proxy.menus.each.with_index do |menu, i|
         FactoryBot.create(:reservation_menu, reservation: reservation, menu: menu, position: i)

         proxy.staffs.each do |staff|
           FactoryBot.create(:staff_menu, staff: staff, menu: menu)
         end
       end

       proxy.staffs.each do |staff|
         FactoryBot.create(:reservation_staff, reservation: reservation, staff: staff)
       end

       proxy.customers.each do |customer|
         FactoryBot.create(:reservation_customer, reservation: reservation, customer: customer)
       end
     end
  end
end
