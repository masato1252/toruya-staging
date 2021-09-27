# frozen_string_literal: true

FactoryBot.define do
  factory :customer do
    association :user
    contact_group { FactoryBot.create(:contact_group, user: user) }
    last_name { Faker::Lorem.word }
    first_name { Faker::Lorem.word }

    transient do
      with_stripe { false }
    end

    after(:create) do |customer, proxy|
      if proxy.with_stripe
        FactoryBot.create(:access_provider, :stripe, user: customer.user)
        Customers::StoreStripeCustomer.run!(customer: customer, authorize_token: StripeMock.create_test_helper.generate_card_token)
      end
    end
  end
end
