FactoryBot.define do
  factory :reservation do
    association :shop
    start_time { Time.zone.now }
    end_time { Time.zone.now.advance(hours: 1) }
    customer_ids { [FactoryBot.create(:customer).id] }
    staffs { [FactoryBot.create(:staff)] }
    menus { [FactoryBot.create(:menu)] }
    prepare_time { start_time - menus.first.interval.minutes }
    ready_time { end_time - menus.last.interval.minutes }

    trait :pending do
      aasm_state { "pending" }
    end

    trait :reserved do
      aasm_state { "reserved" }
    end

     after(:create) do |reservation|
       reservation.reservation_staffs.each do |reservation_staff|
         reservation_staff.update_columns(
           menu_id: reservation.menus.first.id,
           prepare_time: reservation.prepare_time,
           work_start_at: reservation.start_time,
           work_end_at: reservation.end_time,
           ready_time: reservation.ready_time
         )
       end
     end
  end
end
