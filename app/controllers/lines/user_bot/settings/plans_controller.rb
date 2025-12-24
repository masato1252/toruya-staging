# frozen_string_literal: true

class Lines::UserBot::Settings::PlansController < Lines::UserBotDashboardController
  def index
    @plans_properties = Plans::Properties.run!(user: Current.business_owner)
    @plan_labels = I18n.t("plans")[:labels]

    @charge_directly = Current.business_owner.subscription.current_plan.free_level?
    @default_upgrade_plan = params[:upgrade]
    @default_upgrade_rank = Plan.rank(@default_upgrade_plan, Current.business_owner.customers.size) if @default_upgrade_plan

    # プラン初回契約または変更した同日中に、再度プラン変更（アップグレード・ダウングレード）を制限
    @plan_change_restricted_today = plan_change_restricted_today?
    
    # 次回請求時のダウングレード予約プランIDとlevelを取得
    subscription = Current.business_owner.subscription
    @next_plan_id = subscription.next_plan_id
    @next_plan_level = subscription.next_plan ? Plan.permission_level(subscription.next_plan.level) : nil
  end

  private

  def plan_change_restricted_today?
    user = Current.business_owner
    subscription = user.subscription
    
    # 現在有料プランにいる場合のみチェック
    return false unless subscription.in_paid_plan
    
    # 今日完了したmanualなchargeを取得
    today_charge = user.subscription_charges
                      .finished
                      .manual
                      .where(charge_date: Subscription.today)
                      .order(created_at: :desc)
                      .first
    
    return false unless today_charge
    
    # 今日のchargeが無料プランから有料プランへの初回契約かチェック
    # first_chargeが今日のchargeと同じか、または今日のchargeが最初の有料プランへの契約か
    first_charge = subscription.first_charge
    if first_charge && first_charge.id == today_charge.id
      # 初回契約が今日の場合
      return true
    end
    
    # 今日のcharge以前に有料プランへのchargeがない場合も初回契約とみなす
    previous_paid_charge = user.subscription_charges
                               .finished
                               .where("charge_date < ?", Subscription.today)
                               .where.not(plan_id: Subscription::FREE_PLAN_ID)
                               .exists?
    
    !previous_paid_charge
  end
end
