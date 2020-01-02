class Settings::WithdrawalsController < SettingsController
  def index
    @withdrawals = current_user.payment_withdrawals.non_zero.order("id DESC")
  end

  def show
    @withdrawal = current_user.payment_withdrawals.non_zero.find(params[:id])

    options = {
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
