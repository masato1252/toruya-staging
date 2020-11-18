FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "foo#{n}@gmail.com" }
    phone_number { Faker::PhoneNumber.phone_number }
    password { "foobar78" }
    confirmed_at { Time.zone.now }
    referral_token { Devise.friendly_token[0,10] }

    transient do
      skip_default_data { false }
    end

    after(:create) do |user, proxy|
      Users::BuildDefaultData.run!(user: user) unless proxy.skip_default_data
      user.save!
    end
  end
end
