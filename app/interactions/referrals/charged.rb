module Referrals
  class Charged < ActiveInteraction::Base
    object :referral
    object :plan
    object :charge, class: SubscriptionCharge, default: nil # when free plan case, charge is nil

    validate :validate_charge
    validate :validate_referral

    def execute
      if plan.is_child?
        activate_outcome = Referrals::Activate.run(referral: referral)

        # Child accounnt users charge child plans
        if activate_outcome.invalid?
          Rollbar.warning(
            "Unexpected Referral Activate failed",
            errors_messages: activate_outcome.errors.full_messages.join(", "),
            errors_details: activate_outcome.errors.details,
            referral_id: referral,
            charge: charge
          )
        end

        # Refereeses get fee from referrers when referrers pay for child plans
        if referral.referee.business_member?
          referral_fee_outcome = Payments::ReferralFee.run(referral: referral, charge: charge)

          if referral_fee_outcome.invalid?
            Rollbar.warning(
              "Unexpected Create referral fee payment failed",
              errors_messages: referral_fee_outcome.errors.full_messages.join(", "),
              errors_details: referral_fee_outcome.errors.details,
              referral_id: referral,
              charge: charge
            )
          end
        end
      else
        # Child accounnt users upgrade to business_member
        if plan.business_level?
          compose(Payments::ReferralDisconnectFee, referral: referral, charge: charge)
        end

        referrer_cancel_outcome = Referrals::ReferrerCancel.run(referral: referral)

        # Child accounnt users change to other plans
        if referrer_cancel_outcome.invalid?
          Rollbar.warning(
            "Unexpected Referral ReferrerCancel failed",
            errors_messages: referrer_cancel_outcome.errors.full_messages.join(", "),
            errors_details: referrer_cancel_outcome.errors.details,
            referral_id: referral,
            charge: charge
          )
        end
      end
    end

    private

    def validate_referral
      if !referral.pending? && !referral.active?
        errors.add(:referrer, :invald_state)
      end
    end

    def validate_charge
      if charge && !charge.completed?
        errors.add(:charge, :invald_state)
      end

      if !charge && !plan.free_level?
        errors.add(:charge, :invald_plan)
      end
    end
  end
end
