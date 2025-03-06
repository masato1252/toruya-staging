# frozen_string_literal: true

class Lines::UserBot::Metrics::SalePagesController < Lines::UserBotDashboardController
  include ::MetricsHelpers

  def visits
    render json: ::Metrics::SalePagesVisits.run!(
      user: Current.business_owner,
      sale_page_ids: uniq_sale_page_ids,
      metric_period: metric_period,
      demo: params[:demo] == "true"
    )
  end

  def conversions
    render json: ::Metrics::SalePagesConversions.run!(
      user: Current.business_owner,
      sale_page_ids: uniq_sale_page_ids,
      metric_period: metric_period,
      demo: params[:demo] == "true"
    )
  end
end
