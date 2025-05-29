# frozen_string_literal: true

FactoryBot.define do
  factory :subscription do
    user { FactoryBot.create(:user, skip_default_data: true) }
    plan { Plan.free_level.take }
    stripe_customer_id { SecureRandom.hex }
    recurring_day { Subscription.today.day }
    expired_date { Subscription.today.advance(months: 1) }
    trial_days { Plan::TRIAL_PLAN_THRESHOLD_DAYS }
    trial_expired_date { user.created_at.advance(days: trial_days).to_date}
    rank { 0 }

    trait :free do
      plan { Plan.free_level.take }
    end

    trait :free_after_trial do
      plan { Plan.free_level.take }
      trial_expired_date { Subscription.today.advance(days: -1) }
      expired_date { nil }
    end

    trait :basic do
      plan { Plan.basic_level.take }
    end

    trait :premium do
      plan { Plan.premium_level.take }
    end

    trait :business do
      plan { Plan.business_level.take }
    end

    trait :child_basic do
      plan { Plan.child_basic_level.take }
    end

    trait :child_premium do
      plan { Plan.child_premium_level.take }
    end

    trait :with_stripe do
      user { FactoryBot.create(:user, skip_default_data: true, with_stripe_user: true) }
      stripe_customer_id do
        # Create Stripe customer
        customer = Stripe::Customer.create({
          email: user.email,
        }, stripe_account: user.stripe_provider.uid)

        # Create and attach payment method
        payment_method = Stripe::PaymentMethod.create({
          type: 'card',
          card: {
            token: StripeMock.create_test_helper.generate_card_token
          },
        }, stripe_account: user.stripe_provider.uid)

        # Attach payment method to customer
        payment_method.attach({
          customer: customer.id,
        }, stripe_account: user.stripe_provider.uid)

        # Set as default payment method
        Stripe::Customer.update(customer.id, {
          invoice_settings: {
            default_payment_method: payment_method.id,
          },
        }, stripe_account: user.stripe_provider.uid)

        customer.id
      end
    end

    after(:create) do |subscription, proxy|
      user = subscription.user
      Users::BuildDefaultData.run!(user: user)
      user.save!
    end
  end
end
