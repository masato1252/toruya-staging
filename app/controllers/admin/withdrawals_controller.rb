# frozen_string_literal: true

module Admin
  class WithdrawalsController < AdminController
    def mark_paid
      return compat_mark_paid if ENV["COMPAT_API_READ_ENABLED"] == "true"

      PaymentWithdrawals::MarkPaid.run!(payment_withdrawal: PaymentWithdrawal.find(params[:id]))

      redirect_to admin_path
    end

    def receipt
      if ENV["COMPAT_API_READ_ENABLED"] == "true"
        @compat_withdrawal = compat_fetch_v1_json(
          "/admin/withdrawals/#{params[:id]}/receipt_context"
        )&.dig("data")
        unless @compat_withdrawal
          redirect_to admin_path, alert: "出金明細を取得できませんでした"
          return
        end
      else
        @withdrawal = PaymentWithdrawal.find(params[:id])
      end

      options = {
        template: "settings/withdrawals/show",
        pdf: "payment_receipt",
        title: @compat_withdrawal&.dig("created_date") || @withdrawal.created_at.to_date.to_s,
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
