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
    
    # 今日完了したmanualなchargeを取得（初回契約またはアップグレード）
    today_charge = user.subscription_charges
                      .finished
                      .manual
                      .where(charge_date: Subscription.today)
                      .where.not("details ->> 'type' = ?", SubscriptionCharge::TYPES[:downgrade_reservation])
                      .where.not("details ->> 'type' = ?", SubscriptionCharge::TYPES[:downgrade_cancellation])
                      .order(created_at: :desc)
                      .first
    
    # 今日完了したmanualなchargeがあれば、同日中のプラン変更を制限
    return true if today_charge.present?
    
    # 今日作成されたダウングレード予約・キャンセルのchargeをチェック
    today_downgrade_charge = user.subscription_charges
                                  .finished
                                  .where(charge_date: Subscription.today)
                                  .where("details ->> 'type' IN (?, ?)",
                                         SubscriptionCharge::TYPES[:downgrade_reservation],
                                         SubscriptionCharge::TYPES[:downgrade_cancellation])
                                  .order(created_at: :desc)
                                  .first
    
    # 今日ダウングレード予約・キャンセルがあれば、同日中のプラン変更を制限
    today_downgrade_charge.present?
  end
end
