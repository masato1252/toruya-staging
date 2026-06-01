# frozen_string_literal: true

module PlansHelper
  def plan_price(user, plan_level)
    @plan_prices ||= {}

    return @plan_prices[plan_level] if @plan_prices[plan_level]
    if user.currency == "JPY"
      @plan_prices[plan_level] = Plans::Price.run!(user: user, plan: Plan.find_by!(level: plan_level))[0].format(:ja_default_format)
    else
      @plan_prices[plan_level] = Plans::Price.run!(user: user, plan: Plan.find_by!(level: plan_level))[0].format
    end
  end

  def charge_description(charge)
    if charge.is_a?(LineNoticeCharge)
      t("settings.plans.payment.line_notice_request")
    elsif charge.shop_fee?
      if charge.details&.dig("prorated")
        t("settings.plans.payment.extra_shop_prorated")
      else
        t("settings.plans.payment.extra_shop")
      end
    else
      charge.plan.name
    end
  end

  def charge_period_text(charge)
    return unless charge.respond_to?(:details) && charge.details.present?
    return if charge.shop_fee? && charge.details["prorated"]
    return unless charge.details["period_start"].present? && charge.details["period_end"].present?

    "#{l(Date.parse(charge.details["period_start"]))} ~ #{l(Date.parse(charge.details["period_end"]))}"
  end
end
