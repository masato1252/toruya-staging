# frozen_string_literal: true

module Notifiers
  module Users
    class WithdrawalMonthlyReport < Base
      deliver_by_priority [:line, :sms, :email]

      object :withdrawal, class: PaymentWithdrawal

      def message
        I18n.t(
          "notifier.withdrawal_monthly_report.message",
          user_name: user.name,
          transfer_date: withdrawal.details["transfer_date"],
          period: withdrawal.details["period"],
          amount: withdrawal.amount.format
        )
      end
    end
  end
end
