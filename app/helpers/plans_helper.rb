module PlansHelper
  def plan_price(plan_level)
    @plan_prices ||= {}

    return @plan_prices[plan_level] if @plan_prices[plan_level]

    @plan_prices[plan_level] = Plans::Price.run!(user: super_user, plan: Plan.find_by(level: plan_level)).format(ja_default_format: true)
  end
end
