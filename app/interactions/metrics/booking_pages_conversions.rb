# frozen_string_literal: true

module Metrics
  class BookingPagesConversions < ActiveInteraction::Base
    object :user
    array :booking_page_ids do
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

      visit_scope = Ahoy::Visit.where(owner_id: user.id, product_type: "BookingPage")

      metrics = booking_pages.map do |booking_page|
        visit_count = visit_scope.where(product_id: booking_page.id, product_type: "BookingPage").where(started_at: metric_period).count

        reservation_customer_relations = ReservationCustomer.where(created_at: metric_period, booking_page_id: booking_page.id)
        purchased_count = reservation_customer_relations.count
        total_revenue = reservation_customer_relations.sum(:booking_amount_cents)

        {
          label: booking_page&.name,
          visit_count: visit_count,
          purchased_count: purchased_count,
          rate: purchased_count / [visit_count, 1].max.to_f,
          total_revenue: helpers.number_with_delimiter(total_revenue),
          format_rate: helpers.number_to_percentage(purchased_count * 100 / [visit_count, 1].max.to_f, precision: 1)
        }
      end

      metrics.sort_by { |m| m[:rate] ? -m[:rate] : 0 }.sort_by { |m| -m[:visit_count] }
    end

    private

    def helpers
      ApplicationController.helpers
    end

    def booking_pages
      @booking_pages ||= BookingPage.active.where(id: booking_page_ids).to_a
    end
  end
end
