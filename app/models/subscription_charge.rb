# == Schema Information
#
# Table name: subscription_charges
#
#  id              :integer          not null, primary key
#  user_id         :integer
#  plan_id         :integer
#  amount_cents    :decimal(, )
#  amount_currency :string
#  state           :integer
#  charge_date     :date
#  manual          :boolean          default(FALSE), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

class SubscriptionCharge < ApplicationRecord
  belongs_to :user
  belongs_to :plan

  enum state: {
    active: 0,
    completed: 1,
    charge_failed: 2,
    refunded: 3,
  }

  monetize :amount_cents
end
