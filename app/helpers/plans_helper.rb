module PlansHelper
  def plan_price(plan_level)
    @plan_prices ||= {}

    return @plan_prices[plan_level] if @plan_prices[plan_level]

    @plan_prices[plan_level] = Plan.cost_with_currency(plan_level).format(ja_default_format: true)
  end

  def charge_description(charge)
    if charge.shop_fee?
      t("settings.plans.payment.extra_shop")
    else
      charge.plan.name
    end
  end
end
