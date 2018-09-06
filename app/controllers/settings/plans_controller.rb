class Settings::PlansController < SettingsController
  def index
    @plans_properties = Plan.all.each_with_object({}) do |plan, h|
      cost = Plans::Price.run!(user: current_user, plan: plan, ignore_fee: true)

      h[plan.level] = {
        level: plan.level,
        cost: cost.fractional,
        costFormat: cost.format,
        name: plan.name,
        details: I18n.t("settings.plans")[plan.level.to_sym]
      }
    end
    @plan_labels = I18n.t("settings.plans")[:labels]

    @charge_directly = current_user.subscription.current_plan.free_level?
    @default_upgrade_plan = params[:upgrade]
  end
end
