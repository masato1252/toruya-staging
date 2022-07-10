class StripeSubscriptions::ApplySubscriptionCoupon < ActiveInteraction::Base
  string :stripe_subscription_id
  string :coupon_id
  string :stripe_account

  def execute
    begin
      Stripe::Subscription.update(
        stripe_subscription_id,
        {
          coupon: coupon_id,
        },
        { stripe_account: stripe_account }
      )

      Stripe::Coupon.delete(
        coupon_id,
        {},
        { stripe_account: stripe_account }
      )
    rescue Stripe::InvalidRequestError => e
      Rollbar.error(e)
    end
  end
end
