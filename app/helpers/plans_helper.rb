module PlansHelper
  def plan_price(plan_level)
    @plan_prices ||= {}

    return @plan_prices[plan_level] if @plan_prices[plan_level]

    @plan_prices[plan_level] = Plans::Price.run!(user: super_user, plan: Plan.find_by(level: plan_level), ignore_fee: true).format(ja_default_format: true)
  end

  def charge_description(charge)
    if charge.shop_fee?
      t("settings.plans.payment.extra_shop")
    else
      charge.plan.name
    end
  end
end
