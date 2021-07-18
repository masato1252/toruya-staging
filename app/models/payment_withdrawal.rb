# frozen_string_literal: true

# == Schema Information
#
# Table name: payment_withdrawals
#
#  id              :bigint           not null, primary key
#  amount_cents    :decimal(, )      not null
#  amount_currency :string           not null
#  details         :jsonb
#  state           :integer          default("pending"), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  order_id        :string
#  receiver_id     :integer          not null
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
