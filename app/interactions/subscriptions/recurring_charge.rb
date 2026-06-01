# frozen_string_literal: true

module Subscriptions
  class RecurringCharge < ActiveInteraction::Base
    include SlackErrorNotification
    object :subscription

    def execute
      user = subscription.user

      # Use next_plan if it exists, otherwise use current plan
      charging_plan = subscription.next_plan || subscription.plan

      # Check if it's a free plan
      if compose(Plans::Price, user: user, plan: charging_plan)[0].zero?
        # Downgrade to free plan
        Subscriptions::Unsubscribe.run(user: user)

        if referral = Referral.enabled.find_by(referrer: user)
          compose(Referrals::ReferrerCharged, referral: referral, plan: charging_plan)
        end
      else
        # Paid plan, need to process charge
        subscription.with_lock do
          plan_amount, charging_rank = compose(Plans::Price, user: user, plan: charging_plan, rank: subscription.rank)
          shop_fee = compose(Plans::Fee, user: user, plan: charging_plan)
          total_amount = plan_amount + shop_fee

          charge_outcome = Subscriptions::Charge.run(
            user: user,
            plan: charging_plan,
            rank: charging_rank,
            charge_amount: total_amount,
            manual: false
          )

          if charge_outcome.valid?
            charge = charge_outcome.result

            # Update subscription plan and settings
            subscription.plan = charging_plan
            subscription.rank = charge.rank
            subscription.next_plan = nil
            subscription.set_expire_date(is_upgrade: false)
            subscription.save!

            charge.expired_date = subscription.expired_date
            fee = compose(Plans::Fee, user: user, plan: charging_plan)
            charge.details = {
              shop_ids: user.shop_ids,
              shop_fee: fee.fractional,
              shop_fee_format: fee.format,
              type: SubscriptionCharge::TYPES[:plan_subscruption],
              user_name: user.name,
              user_email: user.email,
              plan_amount: Plans::Price.run!(user: user, plan: charging_plan)[0].format,
              plan_name: charging_plan.name,
              rank: subscription.rank
            }
            charge.save!

            Notifiers::Users::Subscriptions::ChargeSuccessfully.run(receiver: subscription.user, user: subscription.user)
          else
            # Merge Charge errors and pass them through
            errors.merge!(charge_outcome.errors)
          end
        end
      end
    end
  end
end
