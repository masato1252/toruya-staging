class Lines::UserBot::Settings::PlansController < Lines::UserBotDashboardController
  def index
    @plans_properties = Plans::Properties.run!(user: current_user)
    @plan_labels = I18n.t("settings.plans")[:labels]

    @charge_directly = current_user.subscription.current_plan.free_level?
    @default_upgrade_plan = params[:upgrade]
  end
end
