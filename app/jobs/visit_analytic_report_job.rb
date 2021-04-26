# frozen_string_literal: true

class VisitAnalyticReportJob < ApplicationJob
  queue_as :low_priority

  def perform(owner_id)
    prev_week = Time.now.prev_week
    start_time = prev_week.beginning_of_week
    end_time = prev_week.end_of_week
    period = start_time..end_time

    report = ["user_id: #{owner_id}"]
    report << "#{I18n.l(start_time, format: :date)} ~ #{I18n.l(end_time, format: :date)}"

    Ahoy::Visit.
      where(started_at: period, owner_id: owner_id).
      group(:product_type, :product_id).count.each do |(product_type, product_id), count|
      # product name, visit, customer visit
      product = product_type.constantize.find_by(id: product_id)
      if product
        customer_visit = Ahoy::Visit.where(started_at: period, owner_id: owner_id, product: product).where.not(customer_social_user_id: nil).count

        report << "Name: #{product.try(:name) || product.product_name}#{product.is_a?(SalePage) ? "(Sale Page)" : ""}, Total visit: #{count}, customer visit: #{customer_visit}"
      end
    end

    Slack::Web::Client.new.chat_postMessage(channel: 'sayhi', text: report.join("\n"))
  end
end
