# frozen_string_literal: true

class Lines::UserBot::Metrics::BookingPagesController < Lines::UserBotDashboardController
  include ::MetricsHelpers

  def visits
    render json: ::Metrics::BookingPagesVisits.run!(
      user: Current.business_owner,
      booking_page_ids: uniq_booking_page_ids,
      metric_period: metric_period,
      demo: params[:demo] == "true"
    )
  end

  def conversions
    render json: ::Metrics::BookingPagesConversions.run!(
      user: Current.business_owner,
      booking_page_ids: uniq_booking_page_ids,
      metric_period: metric_period,
      demo: params[:demo] == "true"
    )
  end
end
