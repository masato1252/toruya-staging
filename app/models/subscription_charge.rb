# == Schema Information
#
# Table name: subscription_charges
#
#  id                    :integer          not null, primary key
#  user_id               :integer
#  plan_id               :integer
#  amount_cents          :decimal(, )
#  amount_currency       :string
#  state                 :integer
#  charge_date           :date
#  expired_date          :date
#  manual                :boolean          default(FALSE), not null
#  stripe_charge_details :jsonb
#  order_id              :string
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#

class SubscriptionCharge < ApplicationRecord
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

  monetize :amount_cents
  validates :order_id, uniqueness: true

  scope :manual, -> { where(manual: true) }
  scope :finished, -> { where(state: [:completed, :refunded])}
end
