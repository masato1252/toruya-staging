# frozen_string_literal: true

module Admin
  class WithdrawalsController < AdminController
    def mark_paid
      return compat_mark_paid if ENV["COMPAT_API_READ_ENABLED"] == "true"

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

    private

    def compat_mark_paid
      response = compat_v1_post_response("/admin/withdrawals/#{params[:id]}/mark_paid")
      unless response&.dig(:success)
        redirect_to admin_path, alert: "出金の更新に失敗しました"
        return
      end

      # v1 only transitions pending -> completed; it does not initiate a
      # Stripe, Square, or bank payout.
      redirect_to response[:body]["redirect_to"].presence || admin_path
    end
  end
end
