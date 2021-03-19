# frozen_string_literal: true

# == Schema Information
#
# Table name: payments
#
#  id                    :bigint(8)        not null, primary key
#  receiver_id           :integer          not null
#  referrer_id           :integer
#  payment_withdrawal_id :integer
#  charge_id             :integer
#  amount_cents          :decimal(, )      not null
#  amount_currency       :string           not null
#  details               :jsonb
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#
# Indexes
#
#  payment_receiver_index  (receiver_id)
#

class Payment < ApplicationRecord
  TYPES = {
    referral_disconnect: "referral_disconnect",
    referral_connect: "referral_connect",
  }.freeze

  belongs_to :receiver, class_name: "User"
  belongs_to :referrer, class_name: "User"
  belongs_to :charge, class_name: "SubscriptionCharge"
  belongs_to :withdrawal, class_name: "PaymentWithdrawal", foreign_key: :payment_withdrawal_id, optional: true

  scope :pending, -> { where(payment_withdrawal_id: nil) }

  monetize :amount_cents
end
