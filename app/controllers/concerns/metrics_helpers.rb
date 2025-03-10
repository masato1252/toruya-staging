# frozen_string_literal: true

module MetricsHelpers
  extend ActiveSupport::Concern

  private

  def metric_start_time
    if params[:start_date].present?
      Time.zone.parse(params[:start_date]).beginning_of_day
    else
      30.days.ago.beginning_of_day
    end
  end

  def metric_end_time
    if params[:end_date].present?
      Time.zone.parse(params[:end_date]).end_of_day
    else
      Time.current
    end
  end

  def metric_period
    metric_start_time..metric_end_time
  end

  def visit_scope
    Ahoy::Visit.where(owner_id: Current.business_owner.id, product_type: "SalePage")
  end

  def uniq_sale_page_ids
    visit_scope.where(started_at: metric_period).select(:product_id).distinct(:product_id).pluck(:product_id)
  end

  def uniq_booking_page_ids
    Ahoy::Visit.where(owner_id: Current.business_owner.id, product_type: "BookingPage")
                .where(started_at: metric_period)
                .select(:product_id)
                .distinct(:product_id)
                .pluck(:product_id)
  end
end
