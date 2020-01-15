module PaymentWithdrawals
  class Create < ActiveInteraction::Base
    TRANSFER_DAY = 10
    object :user

    def execute
      report_month = Subscription.today.prev_month
      period = report_month.beginning_of_month..report_month.end_of_month.end_of_day
      # XXX: Even the period is one month, but try to find all the valid previous pending payments,
      # just in case missing some legacy pending payments.
      payments = user.payments.pending.where("created_at <= ?", report_month.end_of_month.end_of_day)
      total_amount = payments.sum(&:amount)

      PaymentWithdrawal.transaction do
        withdrawal = PaymentWithdrawal.create(
          amount: total_amount,
          receiver: user,
          order_id: SecureRandom.hex(8).upcase,
          details: {
            payment_ids: payments.map(&:id),
            period: "#{I18n.l(period.first)}~#{I18n.l(period.last)}",
            year: report_month.year,
            month: report_month.month,
            transfer_date: I18n.l(transfer_date),
            user_name: user.name,
          }
        )

        if withdrawal.valid?
          payments.update_all(payment_withdrawal_id: withdrawal.id)

          WithdrawalMailer.with(withdrawal: withdrawal).monthly_report.deliver_later
        else
          errors.merge!(withdrawal.errors)
        end

        withdrawal
      end
    end

    private

    def transfer_date
      today = Subscription.today

      date = Date.new(today.year, today.month, TRANSFER_DAY)

      loop do
        if date.sunday? || date.saturday? || date.holiday?(:jp)
          date = date.yesterday
        else
          break
        end
      end

      date
    end
  end
end
