# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "foo#{n}@gmail.com" }
    sequence(:phone_number) { |n| Phonelib.parse("0803623853#{n}", :jp).international(false) }
    password { "foobar78" }
    confirmed_at { Time.zone.now }
    referral_token { Devise.friendly_token[0,10] }

    transient do
      skip_default_data { false }
      with_google_user { false }
      with_stripe_user { false }
    end

    after(:create) do |user, proxy|
      Users::BuildDefaultData.run!(user: user) unless proxy.skip_default_data
      FactoryBot.create(:access_provider, :google, user: user) if proxy.with_google_user
      FactoryBot.create(:access_provider, :stripe, user: user) if proxy.with_stripe_user

      user.save!
    end
  end
end
