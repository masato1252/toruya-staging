class StripeSubscriptions::Retrieve < ActiveInteraction::Base
  string :stripe_subscription_id
  string :stripe_account

  def execute
    begin
      Stripe::Subscription.retrieve(
        stripe_subscription_id,
        { stripe_account: stripe_account }
      )
    rescue Stripe::InvalidRequestError => e
      # subscription already deleted
      Rollbar.error(e)
    end
  end
end
