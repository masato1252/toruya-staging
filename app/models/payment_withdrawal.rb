# frozen_string_literal: true

# == Schema Information
#
# Table name: payment_withdrawals
#
#  id              :bigint(8)        not null, primary key
#  receiver_id     :integer          not null
#  state           :integer          default("pending"), not null
#  amount_cents    :decimal(, )      not null
#  amount_currency :string           not null
#  order_id        :string
#  details         :jsonb
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  payment_withdrawal_order_index           (order_id) UNIQUE
#  payment_withdrawal_receiver_state_index  (receiver_id,state,amount_cents,amount_currency)
#

class PaymentWithdrawal < ApplicationRecord
  belongs_to :receiver, class_name: "User"
  has_many :payments

  enum state: {
    pending: 0,
    completed: 1,
  }

  scope :non_zero, -> { where.not(amount_cents: 0) }

  monetize :amount_cents
end
