# frozen_string_literal: true

class Lines::UserBot::Metrics::SalePagesController < Lines::UserBotDashboardController
  include ::MetricsHelpers

  def visits
    if compat_read_enabled?
      render json: { labels: [], datasets: [] }
      return
    end

    render json: ::Metrics::SalePagesVisits.run!(
      user: Current.business_owner,
      sale_page_ids: uniq_sale_page_ids,
      metric_period: metric_period,
      demo: params[:demo] == "true"
    )
  end

  def conversions
    if compat_read_enabled?
      render json: []
      return
    end

    render json: ::Metrics::SalePagesConversions.run!(
      user: Current.business_owner,
      sale_page_ids: uniq_sale_page_ids,
      metric_period: metric_period,
      demo: params[:demo] == "true"
    )
  end
end
