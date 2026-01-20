# frozen_string_literal: true
# == Schema Information
#
# Table name: subscription_charges
#
#  id                    :bigint           not null, primary key
#  amount_cents          :decimal(, )
#  amount_currency       :string
#  charge_date           :date
#  details               :jsonb
#  error_message         :text
#  expired_date          :date
#  manual                :boolean          default(FALSE), not null
#  rank                  :integer          default(0)
#  state                 :integer          default("active"), not null
#  stripe_charge_details :jsonb
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  order_id              :string
#  plan_id               :bigint
#  user_id               :bigint
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
    downgrade_reservation: "downgrade_reservation",
    downgrade_cancellation: "downgrade_cancellation",
  }.freeze
  belongs_to :user
  belongs_to :plan

  enum state: {
    active: 0,
    completed: 1,
    refunded: 2,
    auth_failed: 3,
    processor_failed: 4,
    refund_failed: 5,
    bonus: 6
  }

  monetize :amount_cents
  validates :order_id, uniqueness: true
  attribute :client_secret

  scope :manual, -> { where(manual: true) }
  scope :finished, -> { where(state: [:completed, :refunded]) }
  scope :displayable_in_history, -> {
    where.not("details ->> 'type' = ?", TYPES[:downgrade_reservation])
         .where.not("details ->> 'type' = ?", TYPES[:downgrade_cancellation])
  }

  def shop_fee?
    details && details["type"] == TYPES[:shop_fee]
  end

  def with_shop_fee?
    details && details["shop_fee"] && details["shop_fee"] != 0
  end

  def downgrade_reservation?
    details && details["type"] == TYPES[:downgrade_reservation]
  end

  def downgrade_cancellation?
    details && details["type"] == TYPES[:downgrade_cancellation]
  end

  def displayable_in_history?
    # 利用履歴に表示するのは、決済が発生したもののみ
    # ダウングレード予約・キャンセルは表示しない
    return false if downgrade_reservation? || downgrade_cancellation?
    true
  end
end
