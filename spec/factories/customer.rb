# frozen_string_literal: true

FactoryBot.define do
  factory :customer do
    association :user
    contact_group { FactoryBot.create(:contact_group, user: user) }
    last_name { Faker::Lorem.word }
    first_name { Faker::Lorem.word }
    reminder_permission { true }

    transient do
      with_stripe { false }
    end

    after(:create) do |customer, proxy|
      if proxy.with_stripe
        FactoryBot.create(:access_provider, :stripe, user: customer.user)
        # Create Stripe customer
        stripe_customer = Stripe::Customer.create(
          {
            email: customer.email,
            phone: customer.phone_number
          },
          stripe_account: customer.user.stripe_provider.uid
        )
        customer.update!(stripe_customer_id: stripe_customer.id)

        # Create and attach a payment method to the customer
        card_token = StripeMock.create_test_helper.generate_card_token
        payment_method = Stripe::PaymentMethod.create(
          {
            type: 'card',
            card: { token: card_token }
          },
          stripe_account: customer.user.stripe_provider.uid
        )

        # Attach the payment method to the customer
        Stripe::PaymentMethod.attach(
          payment_method.id,
          { customer: customer.stripe_customer_id },
          stripe_account: customer.user.stripe_provider.uid
        )

        # Set as default payment method
        Stripe::Customer.update(
          customer.stripe_customer_id,
          {
            invoice_settings: {
              default_payment_method: payment_method.id
            }
          },
          stripe_account: customer.user.stripe_provider.uid
        )
      end
    end
  end
end
