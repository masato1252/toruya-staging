class Settings::PlansController < SettingsController
  def index
    @plans_properties = Plan.all.each_with_object({}) do |plan, h|
      h[plan.level] = {
        cost: plan.cost,
        costFormat: plan.cost_with_currency.format,
        name: plan.name,
        details: I18n.t("settings.plans")[plan.level.to_sym]
      }
    end
    @plan_labels = I18n.t("settings.plans")[:labels]
  end

  def create
    outcome = Plans::Subscribe.run(user: current_user, plan: Plan.find_by(level: :basic), authorize_token: params[:token], manually: true)

    if outcome.valid?
      head(:ok)
    else
      render json: { message: outcome.errors.full_messages.join("") }, status: :unprocessable_entity
    end
  end
end
