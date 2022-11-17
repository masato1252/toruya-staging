# frozen_string_literal: true

module Metrics
  class OnlineServicesRevenues < ActiveInteraction::Base
    object :user
    object :metric_period, class: Range

    def execute
      customer_ids = user.customer_ids
      # e.g. relation_id_mapping_payments
      #
      # {
      #   552 => 19999999.0,
      #   554 => 10000.0,
      #   556 => 10000.0,
      #   551 => 111.0
      # }
      relation_id_mapping_payments = CustomerPayment.
        select(:product_id).
        where(customer_id: customer_ids, product_type: "OnlineServiceCustomerRelation").
        completed.
        where(created_at: metric_period).
        group(:product_id).
        order("sum_amount_cents DESC").
        sum(:amount_cents)

      # e.g. relations_group_by_online_service_id
      #
      # {
      #   <OnlineServiceCustomerRelation:0x00007fcb67302750> {
      #     "id" => nil,
      #     "online_service_id" => 75,
      #     "relation_ids" => [
      #       309,
      #       312,
      #     ]
      #   },
      #   ...
      # }
      relations_group_by_online_service_id = OnlineServiceCustomerRelation.
        select("online_service_id, array_agg(id) as relation_ids").
        where(id: relation_id_mapping_payments.keys).
        group(:online_service_id)

      online_services = OnlineService.where(id: relations_group_by_online_service_id.pluck(:online_service_id)).to_a

      # [
      #   {
      #     :service => <OnlineService:0x00007faf87ae3178> { :id => 139 },
      #     :total_amount => 19999999.0
      #   }
      # ]
      relations_group_by_online_service_id.map do |relation|
        online_service_id = relation.online_service_id
        relation_ids = relation.relation_ids
        online_service = online_services.find { |service| service.id == online_service_id  }

        {
          service: online_service,
          total_revenue: relation_ids.sum { |relation_id| relation_id_mapping_payments[relation_id] }.to_i
        }
      end.sort_by {|h| -h[:total_revenue] }
    end
  end
end
