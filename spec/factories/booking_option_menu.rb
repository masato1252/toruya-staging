FactoryBot.define do
  factory :booking_option_menu do
    association :menu
    association :booking_option
  end
end
