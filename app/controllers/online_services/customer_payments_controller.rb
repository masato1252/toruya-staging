# frozen_string_literal: true

module OnlineServices
  class CustomerPaymentsController < ::OnlineServicesController
    def new
      relation = online_service.online_service_customer_relations.where(customer: current_customer).first
      price = relation.price_details.find { |price| price.order_id == params[:order_id] }
    end

    def create
      # OnlineServiceCustomerRelation.last.price_details.find { |price| price.order_id ==  OnlineServiceCustomerRelation.last.customer_payments.last.order_id }
      relation = online_service.online_service_customer_relations.where(customer: current_customer).first
      price = relation.price_details.find { |price| price.order_id == params[:order_id] }

      CustomerPayments::PurchaseOnlineService.run(
        online_service_customer_relation: relation,
        online_service_customer_price: price,
        manual: true
      )
    end
  end
end
