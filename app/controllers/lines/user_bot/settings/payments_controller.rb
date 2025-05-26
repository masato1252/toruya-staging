# frozen_string_literal: true

class Lines::UserBot::Settings::PaymentsController < Lines::UserBotDashboardController
  skip_before_action :authenticate_current_user!, only: [:receipt]
  skip_before_action :authenticate_super_user, only: [:receipt]

  def index
    @subscription = Current.business_owner.subscription
    @charges = Current.business_owner.subscription_charges.finished.includes(:plan).where("created_at >= ?", 1.year.ago).order("created_at DESC")
    @refundable = @subscription.refundable?
  end

  def create
    new_plan = Plan.find_by!(level: params[:plan])

    outcome =
      if new_plan.business_level?
        Plans::SubscribeBusinessPlan.run(user: Current.business_owner, authorize_token: params[:token], payment_intent_id: params[:payment_intent_id])
      elsif new_plan.is_child?
        Plans::SubscribeChildPlan.run(
          user: Current.business_owner,
          plan: new_plan,
          rank: params[:rank],
          authorize_token: params[:token],
          change_immediately: params[:change_immediately],
          payment_intent_id: params[:payment_intent_id]
        )
      else
        Plans::Subscribe.run(
          user: Current.business_owner,
          plan: new_plan,
          rank: params[:rank],
          authorize_token: params[:token],
          change_immediately: params[:change_immediately],
          payment_intent_id: params[:payment_intent_id]
        )
      end

    if outcome.invalid?
      Rollbar.error(
        "Payment create failed",
        errors_messages: outcome.errors.full_messages.join(", "),
        errors_details: outcome.errors.details,
        params: params
      )

      error_with_client_secret = find_error_with_client_secret(outcome)

      render json: {
         message: outcome.errors.full_messages.join(""),
         client_secret: error_with_client_secret[:client_secret],
         payment_intent_id: error_with_client_secret[:payment_intent_id]
      }, status: :unprocessable_entity
    else
      render json: { redirect_path: lines_user_bot_settings_path(business_owner_id: business_owner_id) }
    end
  end

  def change_card
    outcome = Payments::StoreStripeCustomer.run(
      user: Current.business_owner,
      authorize_token: params[:token],
      setup_intent_id: params[:setup_intent_id]
    )

    if outcome.invalid?
      # Check if this is a 3DS case requiring client-side action
      if outcome.errors.details.dig(:user)&.any? { |error| error[:error] == :requires_action }
        user_error = outcome.errors.details[:user].find { |error| error[:error] == :requires_action }
        render json: {
          message: outcome.errors.full_messages.join(""),
          client_secret: user_error[:client_secret],
          setup_intent_id: user_error[:setup_intent_id]
        }, status: :unprocessable_entity
      else
        render json: {
          message: outcome.errors.full_messages.join("")
        }, status: :unprocessable_entity
      end
    else
      render json: {
        redirect_to: lines_user_bot_settings_path(business_owner_id: business_owner_id)
      }
    end
  end

  def refund
    outcome = Subscriptions::Refund.run(user: Current.business_owner)

    if outcome.valid?
      flash[:notice] = I18n.t("settings.plans.payment.refund_successfully_message")
    else
      flash[:alert] =  I18n.t("settings.plans.payment.refund_failed_message")
    end

    redirect_to lines_user_bot_settings_payments_path(business_owner_id: business_owner_id)
  end

  def receipt
    user_id = MessageEncryptor.decrypt(params[:encrypted_user_id])
    @charge = User.find(user_id).subscription_charges.find(params[:id])

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
    Subscriptions::Unsubscribe.run(user: Current.business_owner)

    redirect_to lines_user_bot_settings_path(business_owner_id: business_owner_id)
  end
end
