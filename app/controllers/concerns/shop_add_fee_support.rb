# frozen_string_literal: true

module ShopAddFeeSupport
  extend ActiveSupport::Concern

  private

  def shop_fee_required_for_add?(owner)
    owner.permission_level != Plan::ENTERPRISE_LEVEL &&
      owner.shops.count >= Plans::Fee::SHOP_NUMBER_CHARGE_THRESHOLD &&
      Plans::Fee.chargeable_for?(owner, owner.subscription.plan)
  end

  def load_shop_add_proration_preview(owner)
    Subscriptions::ShopFeeProration.run!(user: owner)
  end

  def shop_add_error_payload(outcome)
    charge = outcome.result
    error_payload = { message: outcome.errors.full_messages.join(", ") }

    if charge&.client_secret.present?
      error_payload[:client_secret] = charge.client_secret
      error_payload[:payment_intent_id] = charge.stripe_charge_details&.dig("id")
    elsif outcome.errors.details.dig(:plan, 0, :client_secret)
      error_payload.merge!(outcome.errors.details[:plan].first.slice(:client_secret, :payment_intent_id))
    end

    error_payload
  end
end
