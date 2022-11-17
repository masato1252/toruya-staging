# frozen_string_literal: true

module Metrics
  class SalePagesConversions < ActiveInteraction::Base
    object :user
    array :sale_page_ids do
      integer
    end
    object :metric_period, class: Range
    boolean :demo, default: false

    def execute
      if demo
        return [
          {
            "label":"劉式４×３フォーミュラ DH",
            "visit_count":9,
            "purchased_count":3,
            "rate":0.3333333333333333,
            "format_rate":"33.3%"
          },
          {
            "label":"member6",
            "visit_count":9,
            "purchased_count":1,
            "rate":0.1111111111111111,
            "format_rate":"11.1%"
          },
          {
            "label":7,
            "visit_count":8,
            "purchased_count":2,
            "rate":0.25,
            "format_rate":"25.0%"
          }
        ]
      end

      visit_scope = Ahoy::Visit.where(owner_id: user.id, product_type: "SalePage")
      sale_pages = SalePage.where(id: sale_page_ids).includes(:product).to_a

      metrics = sale_page_ids.map do |product_id|
        sale_page = sale_pages.find { |page| page.id == product_id }
        visit_count = visit_scope.where(product_id: product_id, product_type: "SalePage").where(started_at: metric_period).count

        purchased_count =
          if sale_page&.is_booking_page?
            nil
          else
            OnlineServiceCustomerRelation.where(paid_at: metric_period, sale_page_id: product_id).count
          end

        {
          label: sale_page&.internal_name&.presence || sale_page&.internal_product_name || product_id,
          visit_count: visit_count,
          purchased_count: purchased_count,
          rate: purchased_count ? purchased_count / visit_count.to_f : nil,
          format_rate: purchased_count ? ApplicationController.helpers.number_to_percentage(purchased_count * 100 / visit_count.to_f, precision: 1) : nil
        }
      end

      metrics.sort_by { |m| m[:rate] ? -m[:rate] : -1_000 }.sort_by { |m| -m[:visit_count] }
    end
  end
end
