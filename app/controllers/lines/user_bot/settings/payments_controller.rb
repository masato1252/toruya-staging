class Lines::UserBot::Settings::PaymentsController < Lines::UserBotDashboardController
  def index
    @subscription = current_user.subscription
    @charges = current_user.subscription_charges.finished.includes(:plan).where("created_at >= ?", 1.year.ago).order("created_at DESC")
    @refundable = @subscription.refundable?
  end

  def create
    new_plan = Plan.find_by!(level: params[:plan])

    outcome =
      if new_plan.business_level?
        Plans::SubscribeBusinessPlan.run(user: current_user, authorize_token: params[:token])
      elsif new_plan.is_child?
        Plans::SubscribeChildPlan.run(
          user: current_user,
          plan: new_plan,
          authorize_token: params[:token],
          change_immediately: params[:change_immediately]
        )
      else
        Plans::Subscribe.run(
          user: current_user,
          plan: new_plan,
          authorize_token: params[:token],
          change_immediately: params[:change_immediately]
        )
      end

    if outcome.invalid?
      Rollbar.warning(
        "Payment create failed",
        errors_messages: outcome.errors.full_messages.join(", "),
        errors_details: outcome.errors.details,
        params: params
      )

      render json: { message: outcome.errors.full_messages.join("") }, status: :unprocessable_entity
    else
      render json: { redirect_path: flash[:redirect_to] || lines_user_bot_settings_path }
    end
  end

  def refund
    outcome = Subscriptions::Refund.run(user: current_user)

    if outcome.valid?
      flash[:notice] = I18n.t("settings.plans.payment.refund_successfully_message")
    else
      flash[:alert] =  I18n.t("settings.plans.payment.refund_failed_message")
    end

    redirect_to lines_user_bot_settings_payments_path
  end

  def receipt
    @charge = current_user.subscription_charges.find(params[:id])

    options = {
      template: "settings/payments/receipt",
      pdf: "subscription_receipt",
      title: @charge.created_at.to_date.to_s,
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

  def downgrade
    current_user.subscription.update_columns(plan_id: Subscription::FREE_PLAN_ID)

    redirect_to lines_user_bot_settings_path
  end
end
