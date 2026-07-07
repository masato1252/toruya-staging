# frozen_string_literal: true

class Lines::UserBot::Metrics::OnlineServicesController < Lines::UserBotDashboardController
  include ::MetricsHelpers

  def sale_pages_visits
    if compat_read_enabled?
      render json: { labels: [], datasets: [] }
      return
    end

    render json: ::Metrics::SalePagesVisits.run!(
      user: Current.business_owner,
      sale_page_ids: sale_page_ids,
      metric_period: metric_period,
      demo: params[:demo] == "true"
    )
  end

  def sale_pages_conversions
    if compat_read_enabled?
      render json: []
      return
    end

    render json: ::Metrics::SalePagesConversions.run!(
      user: Current.business_owner,
      sale_page_ids: sale_page_ids,
      online_service_id: params[:id],
      metric_period: metric_period,
      demo: params[:demo] == "true"
    )
  end

  private

  def sale_page_ids
    SalePage.where(product_id: params[:id], product_type: 'OnlineService').pluck(:id)
  end
end
