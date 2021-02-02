# frozen_string_literal: true

module Subscriptions
  class Refund < ActiveInteraction::Base
    object :user

    validate :validate_refundable

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
            errors.add(:user, :refund_failed)
          end
        rescue Stripe::CardError, Stripe::StripeError => error
          errors.add(:user, :refund_failed)
        end
      end
    end

    private

    def first_charge
      @first_charge ||= user.subscription.first_charge
    end

    def validate_refundable
      errors.add(:user, :subscription_is_not_refundable) unless user.subscription.refundable?
    end
  end
end
