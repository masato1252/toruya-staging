class StripeSubscriptions::IsCanceled < ActiveInteraction::Base
  string :stripe_subscription_id
  string :stripe_account

  def execute
    stripe_subscription = compose(
      StripeSubscriptions::Retrieve,
      stripe_subscription_id: stripe_subscription_id,
      stripe_account: stripe_account
    )

    stripe_subscription ? stripe_subscription.status == STRIPE_SUBSCRIPTION_STATUS[:canceled] : true
  end
end
