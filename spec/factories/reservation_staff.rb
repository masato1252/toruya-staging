# frozen_string_literal: true

FactoryBot.define do
  factory :reservation_staff do
    reservation { FactoryBot.create(:reservation) }
    staff { FactoryBot.create(:staff, user: reservation.shop.user) }
    menu { reservation.menus.first }
    prepare_time { reservation.prepare_time }
    work_start_at { reservation.start_time }
    work_end_at { reservation.end_time }
    ready_time { reservation.ready_time }
  end
end
