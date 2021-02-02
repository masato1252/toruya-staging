# frozen_string_literal: true

module Admin
  class WithdrawalsController < AdminController
    def mark_paid
      PaymentWithdrawals::MarkPaid.run!(payment_withdrawal: PaymentWithdrawal.find(params[:id]))

      redirect_to admin_path
    end

    def receipt
      @withdrawal = PaymentWithdrawal.find(params[:id])

      options = {
        template: "settings/withdrawals/show",
        pdf: "payment_receipt",
        title: @withdrawal.created_at.to_date.to_s,
        show_as_html: params.key?('debug'),
        page_width: 210,
        page_height: 297,
        lowquality: Rails.env.development?,
        margin: {
          top: 22,
          left: 20,
          right: 20,
          bottom: 0
        }
      }

      render options
    end
  end
end
