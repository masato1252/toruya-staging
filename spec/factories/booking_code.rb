require "random_code"

FactoryBot.define do
  factory :booking_code do
    uuid { SecureRandom.uuid }
    code { RandomCode.generate(6) }
  end
end
