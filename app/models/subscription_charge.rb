# frozen_string_literal: true

# == Schema Information
#
# Table name: subscription_charges
#
#  id                    :bigint(8)        not null, primary key
#  user_id               :bigint(8)
#  plan_id               :bigint(8)
#  amount_cents          :decimal(, )
#  amount_currency       :string
#  state                 :integer          default("active"), not null
#  charge_date           :date
#  expired_date          :date
#  manual                :boolean          default(FALSE), not null
#  stripe_charge_details :jsonb
#  order_id              :string
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  details               :jsonb
#
# Indexes
#
#  index_subscription_charges_on_plan_id  (plan_id)
#  order_id_index                         (order_id)
#  subscription_charge_type_index         (((details ->> 'type'::text)))
#  user_state_index                       (user_id,state)
#

# The model represents the data we charge users
class SubscriptionCharge < ApplicationRecord
  TYPES = {
    shop_fee: "shop_fee",
    plan_subscruption: "plan_subscruption",
    business_member_sign_up: "business_member_sign_up",
  }.freeze
  belongs_to :user
  belongs_to :plan

  enum state: {
    active: 0,
    completed: 1,
    refunded: 2,
    auth_failed: 3,
    processor_failed: 4,
    refund_failed: 5
  }

  monetize :amount_cents, numericality: { greater_than: 0 }
  validates :order_id, uniqueness: true

  scope :manual, -> { where(manual: true) }
  scope :finished, -> { where(state: [:completed, :refunded]) }

  def shop_fee?
    details && details["type"] == TYPES[:shop_fee]
  end

  def with_shop_fee?
    details && details["shop_fee"] != 0
  end
end
