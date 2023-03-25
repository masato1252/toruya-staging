# frozen_string_literal: true

module Metrics
  class SalePagesConversions < ActiveInteraction::Base
    object :user
    array :sale_page_ids do
      integer
    end
    integer :online_service_id, default: nil
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
            "format_rate":"33.3%",
            "total_revenue": helpers.number_with_delimiter(10000)
          },
          {
            "label":"member6",
            "visit_count":9,
            "purchased_count":1,
            "rate":0.1111111111111111,
            "format_rate":"11.1%",
            "total_revenue": helpers.number_with_delimiter(1000)
          },
          {
            "label":7,
            "visit_count":8,
            "purchased_count":2,
            "rate":0.25,
            "format_rate":"25.0%",
            "total_revenue": 100
          }
        ]
      end

      visit_scope = Ahoy::Visit.where(owner_id: user.id, product_type: "SalePage")
      sale_pages = SalePage.where(id: sale_page_ids).includes(:product).to_a

      metrics = sale_page_ids.map do |product_id|
        sale_page = sale_pages.find { |page| page.id == product_id }
        visit_count = visit_scope.where(product_id: product_id, product_type: "SalePage").where(started_at: metric_period).count
        relations = OnlineServiceCustomerRelation.where(created_at: metric_period, sale_page_id: product_id).current
        relations = relations.where(online_service_id: online_service_id) if online_service_id

        purchased_count =
          if sale_page&.is_booking_page?
            nil
          else
            relations.count
          end

        {
          label: sale_page&.internal_sale_name,
          visit_count: visit_count,
          purchased_count: purchased_count,
          rate: purchased_count ? purchased_count / [visit_count, 1].max.to_f : nil,
          total_revenue: purchased_count ? helpers.number_with_delimiter(CustomerPayment.where(product_type: "OnlineServiceCustomerRelation", product_id: relations.select(:id)).completed.sum(:amount_cents).to_i) : nil,
          format_rate: purchased_count ? helpers.number_to_percentage(purchased_count * 100 / [visit_count, 1].max.to_f, precision: 1) : nil
        }
      end

      metrics.sort_by { |m| m[:rate] ? -m[:rate] : 0 }.sort_by { |m| -m[:visit_count] }
    end

    private

    def helpers
      ApplicationController.helpers
    end
  end
end
