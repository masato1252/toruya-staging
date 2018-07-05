module Subscriptions
  class Refund < ActiveInteraction::Base
    object :user

    validate :validate_refunded_state
    validate :validate_charge_date

    def execute
      first_charge.transaction do
        subscription = user.subscription

        begin
          stripe_refund = Stripe::Refund.create({charge: first_charge.stripe_charge_details["id"]})

          if stripe_refund.status == "succeeded"
            first_charge.refunded!
            subscription.next_plan = nil
            subscription.expire
            subscription.save!
          else
            # [TODO] What should we do?
          end
        rescue Stripe::CardError, Stripe::StripeError => error
          # [TODO] What should we do?
        end
      end
    end

    private

    def first_charge
      @first_charge ||= user.subscription_charges.manual.first
    end

    def validate_refunded_state
      errors.add(:user, :charge_refunded) if first_charge.refunded?
    end

    def validate_charge_date
      if first_charge.created_at < 8.days.ago
        errors.add(:user, :over_refundable_time)
      end
    end
  end
end
