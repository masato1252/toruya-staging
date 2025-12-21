# frozen_string_literal: true

class Settings::PaymentsController < SettingsController
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
      render json: { message: outcome.errors.full_messages.join("") }, status: :unprocessable_entity
    else
      render json: { redirect_path: settings_plans_path }
    end
  end

  def refund
    outcome = Subscriptions::Refund.run(user: current_user)

    if outcome.valid?
      flash[:notice] = I18n.t("settings.plans.payment.refund_successfully_message")
    else
      flash[:alert] =  I18n.t("settings.plans.payment.refund_failed_message")
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
    user = current_user
    
    # 選択されたプランを取得（パラメータがない場合は無料プランへのダウングレードとみなす）
    if params[:plan].present?
      plan = Plan.find_by!(level: params[:plan])
      rank = params[:rank].to_i || 0
      
      # 無料プランへのダウングレードの場合
      if plan.free_level?
        outcome = Subscriptions::Unsubscribe.run(user: user)
      else
        # 有料プラン間のダウングレードの場合、次回請求時に新プランで請求されるようにnext_planを設定
        outcome = Plans::Subscribe.run(
          user: user,
          plan: plan,
          rank: rank,
          change_immediately: false  # 次回請求時に変更
        )
      end
      
      unless outcome.valid?
        flash[:alert] = outcome.errors.full_messages.join(", ")
      end
    else
      # プランが指定されていない場合は無料プランへのダウングレード
      outcome = Subscriptions::Unsubscribe.run(user: user)
    end

    redirect_to settings_plans_path
  end
end
