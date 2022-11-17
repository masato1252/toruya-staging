# frozen_string_literal: true

class Lines::UserBot::Metrics::OnlineServicesController < Lines::UserBotDashboardController
  include ::MetricsHelpers

  def sale_pages_visits
    render json: ::Metrics::SalePagesVisits.run!(
      user: current_user,
      sale_page_ids: sale_page_ids,
      metric_start_time: metric_start_time,
      demo: params[:demo] == "true"
    )
  end

  def sale_pages_conversions
    render json: ::Metrics::SalePagesConversions.run!(
      user: current_user,
      sale_page_ids: sale_page_ids,
      metric_period: metric_period,
      demo: params[:demo] == "true"
    )
  end

  private

  def sale_page_ids
    SalePage.where(product_id: params[:id], product_type: 'OnlineService').pluck(:id)
  end
end
