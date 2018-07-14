class Settings::PaymentsController < SettingsController
  def index
    @subscription = current_user.subscription
    charges = current_user.subscription_charges
    @charges = charges.completed.or(charges.refunded).where("created_at >= ?", 1.year.ago).order("created_at DESC")
    @refundable = @subscription.refundable?
  end

  def create
    outcome = Plans::Subscribe.run(
      user: current_user,
      plan: Plan.find_by(level: params[:plan]),
      authorize_token: params[:token],
      upgrade_immediately: params[:upgrade_immediately]
    )

    if outcome.invalid?
      render json: { message: outcome.errors.full_messages.join("") }, status: :unprocessable_entity
    end
  end

  def refund
    outcome = Subscriptions::Refund.run(user: current_user)

    if outcome.valid?
      flash[:notice] = "Refund successfully"
    else
      flash[:alert] =  "Refund failed, please try again or try to contact with us info@toruya.com"
    end

    redirect_to settings_payments_path
  end

  def receipt
    @charge = current_user.subscription_charges.find(params[:id])

    options = {
      pdf: "subscription_receipt",
      title: @charge.created_at.to_date.to_s,
      show_as_html: params.key?('debug'),
      page_width: 210,
      page_height: 297,
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
