# frozen_string_literal: true

module Subscriptions
  class RecurringCharge < ActiveInteraction::Base
    object :subscription

    def execute
      user = subscription.user

      charging_plan = subscription.next_plan || subscription.plan

      if compose(Plans::Price, user: user, plan: charging_plan).zero?
        # Downgrade to free plan
        subscription.update(plan: charging_plan, next_plan: nil, rank: 0)

        if referral = Referral.enabled.find_by(referrer: user)
          compose(Referrals::ReferrerCharged, referral: referral, plan: charging_plan)
        end
      else
        subscription.with_lock do
          charge_outcome = Subscriptions::Charge.run(user: user, plan: charging_plan, rank: subscription.rank, manual: false)

          if charge_outcome.valid?
            charge = charge_outcome.result
            subscription.plan = charging_plan
            subscription.rank = charge.rank
            subscription.next_plan = nil
            subscription.set_expire_date
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
              plan_amount: Plans::Price.run!(user: user, plan: charging_plan).format,
              plan_name: charging_plan.name,
              rank: subscription.rank
            }
            charge.save!

            Notifiers::Subscriptions::ChargeSuccessfully.run(receiver: subscription.user, user: subscription.user)
          else
            errors.merge!(charge_outcome.errors)
          end
        end
      end
    end
  end
end
