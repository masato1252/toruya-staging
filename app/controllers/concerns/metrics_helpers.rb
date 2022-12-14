# frozen_string_literal: true

module MetricsHelpers
  extend ActiveSupport::Concern

  private

  def metric_start_time
    31.days.ago.beginning_of_day
  end

  def metric_period
    metric_start_time..Time.current
  end

  def visit_scope
    Ahoy::Visit.where(owner_id: current_user.id, product_type: "SalePage")
  end

  def uniq_sale_page_ids
    visit_scope.where(started_at: metric_period).select(:product_id).distinct(:product_id).pluck(:product_id)
  end
end
