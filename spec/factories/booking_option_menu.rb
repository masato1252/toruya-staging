FactoryBot.define do
  factory :booking_option_menu do
    association :menu
    association :booking_option
    required_time { menu.minutes }
  end
end
