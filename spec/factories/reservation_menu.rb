# frozen_string_literal: true

FactoryBot.define do
  factory :reservation_menu do
    reservation { FactoryBot.create(:reservation) }
    menu { FactoryBot.create(:menu, user: reservation.shop.user) }
    required_time { menu.minutes }
    position { 0 }
  end
end
