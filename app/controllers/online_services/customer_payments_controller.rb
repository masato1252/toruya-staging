# frozen_string_literal: true

module OnlineServices
  class CustomerPaymentsController < ::OnlineServicesController
    def new
      @relation = online_service.online_service_customer_relations.where(customer: current_customer).first
      @price = @relation.price_details.find { |price| price.order_id == params[:order_id] }
    end

    def create
      relation = online_service.online_service_customer_relations.where(customer: current_customer).first
      price = relation.price_details.find { |price| price.order_id == params[:order_id] }

      outcome = CustomerPayments::PurchaseOnlineService.run(
        online_service_customer_relation: relation,
        online_service_customer_price: price,
        manual: true
      )

      return_json_response(outcome, {
        redirect_to: customer_status_online_service_path(slug: params[:slug], encrypted_social_service_user_id: params[:encrypted_social_service_user_id])
      })
    end

    def change_card
      outcome = Customers::StoreStripeCustomer.run(customer: current_customer, authorize_token: params[:token])

      return_json_response(outcome, {
        redirect_to: customer_status_online_service_path(slug: params[:slug], encrypted_social_service_user_id: params[:encrypted_social_service_user_id])
      })
    end
  end
end
