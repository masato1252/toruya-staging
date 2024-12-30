# frozen_string_literal: true

require "slack_client"
require "order_id"

module Subscriptions
  class Charge < ActiveInteraction::Base
    object :user
    object :plan
    boolean :manual
    object :charge_amount, class: Money, default: nil
    integer :rank, default: nil
    string :charge_description, default: nil

    def execute
      SubscriptionCharge.transaction do
        I18n.with_locale(user.locale) do
          order_id = OrderId.generate
          # XXX: business plan charged manually means, it is a registration charge, user need to pay extra signup fee
          amount, charging_rank =
          if charge_amount && rank
            [charge_amount, rank]
          else
            compose(Plans::Price, user: user, plan: plan, rank: rank)
          end

          description = charge_description || plan.level

          charge = user.subscription_charges.create!(
            plan: plan,
            rank: charging_rank,
            amount: amount,
            charge_date: Subscription.today,
            manual: manual,
            order_id: order_id
          )

          begin
            stripe_charge = Stripe::Charge.create({
              amount: amount.fractional * amount.currency.default_subunit_to_unit,
              currency: amount.currency.iso_code,
              customer: user.subscription.stripe_customer_id,
              description: description,
              statement_descriptor: "Toruya #{description}",
              metadata: {
                charge_id: charge.id,
                level: plan.level,
                rank: charging_rank,
                user_id: user.id,
                order_id: order_id
              }
            })

            # credit card charge is synchronous request, it would return final status immediately
            charge.stripe_charge_details = stripe_charge.as_json
            charge.completed!

            if Rails.configuration.x.env.production?
              if user.subscription_charges.finished.count == 1
                text = "💭 `🎉 user_id: #{user.id}` #{"<#{Rails.application.routes.url_helpers.admin_chats_url(user_id: user.id)}|chat link>"} new Paid user"
                SlackClient.send(channel: 'new_paid_users', text: text)
              elsif manual
                text = "💭 `🎉 user_id: #{user.id}` #{"<#{Rails.application.routes.url_helpers.admin_chats_url(user_id: user.id)}|chat link>"} user upgraded"
                SlackClient.send(channel: 'new_paid_users', text: text)
              else
                SlackClient.send(channel: 'sayhi', text: "[OK] 🎉Subscription Stripe charge user: #{user.id} 💰")
              end
            end
          rescue Stripe::CardError => error
            charge.stripe_charge_details = error.json_body[:error]
            charge.auth_failed!
            errors.add(:plan, :auth_failed)

            unless manual
              Notifiers::Users::Subscriptions::ChargeFailed.run(
                receiver: user,
                user: user,
                subscription_charge: charge
              )
            end

            if Rails.configuration.x.env.production?
              SlackClient.send(channel: 'sayhi', text: "[Failed] Subscription Stripe charge user: #{user.id}, #{error}")
              Rollbar.error(error, toruya_charge: charge.id, stripe_charge: error.json_body[:error])
            end
          rescue Stripe::StripeError => error
            charge.stripe_charge_details = error.json_body[:error]
            charge.processor_failed!
            errors.add(:plan, :processor_failed)

            unless manual
              Notifiers::Users::Subscriptions::ChargeFailed.run(
                receiver: user,
                user: user,
                subscription_charge: charge
              )
            end

            if Rails.configuration.x.env.production?
              SlackClient.send(channel: 'sayhi', text: "[Failed] Subscription Stripe charge user: #{user.id}, #{error}")
              Rollbar.error(error, toruya_charge: charge.id, stripe_charge: error.json_body[:error])
            end
          rescue => e
            Rollbar.error(e)
            errors.add(:plan, :something_wrong)
          end

          # XXX: Put the fee and referral behviors here is because the of plans changes behaviors
          # might not happen right away, it might happend in next charge,
          # so Subscriptions::Charge is the place, every charge hehavior will called.
          # So put it here to handle all kind of charge or plan changes.
          if charge.completed? && referral = Referral.enabled.find_by(referrer: user)
            compose(Referrals::ReferrerCharged, charge: charge, referral: referral, plan: plan)
          end

          charge
        end
      end
    end
  end
end
