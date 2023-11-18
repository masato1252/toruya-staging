# frozen_string_literal: true

class Lines::UserBot::Settings::PlansController < Lines::UserBotDashboardController
  def index
    @plans_properties = Plans::Properties.run!(user: Current.business_owner)
    @plan_labels = I18n.t("plans")[:labels]

    @charge_directly = Current.business_owner.subscription.current_plan.free_level?
    @default_upgrade_plan = params[:upgrade]
    @default_upgrade_rank = Plan.rank(@default_upgrade_plan, Current.business_owner.customers.size) if @default_upgrade_plan
  end
end
