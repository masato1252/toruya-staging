class Settings::PlansController < SettingsController
  def index
    @plans_properties = Plan.all.each_with_object({}) do |plan, h|
      h[plan.level] = {
        level: plan.level,
        cost: plan.cost,
        costFormat: plan.cost_with_currency.format,
        name: plan.name,
        details: I18n.t("settings.plans")[plan.level.to_sym]
      }
    end
    @plan_labels = I18n.t("settings.plans")[:labels]

    @charge_directly = current_user.subscription.current_plan.free_level?
  end
end
