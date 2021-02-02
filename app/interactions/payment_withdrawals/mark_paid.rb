# frozen_string_literal: true

module PaymentWithdrawals
  class MarkPaid < ActiveInteraction::Base
    object :payment_withdrawal

    def execute
      payment_withdrawal.completed!
    end
  end
end
