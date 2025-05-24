# frozen_string_literal: true

module OnlineServices
  class CustomerPaymentsController < ::OnlineServicesController
    def new
      @relation = online_service.online_service_customer_relations.where(customer: current_customer).last
      # subscription there is no order_id for each payment
      @price =
        if @relation.online_service.recurring_charge_required?
          @relation.price_details.first
        else
          @relation.price_details.find { |price| price.order_id == params[:order_id] }
        end
    end

    def create
      relation = online_service.online_service_customer_relations.where(customer: current_customer).last

      Customers::StoreStripeCustomer.run!(customer: relation.customer, authorize_token: params[:token])

      outcome =
        if online_service.recurring_charge_required?
          CustomerPayments::SubscribeOnlineService.run(
            online_service_customer_relation: relation
          )
        else
          price = relation.price_details.find { |price| price.order_id == params[:order_id] }

          CustomerPayments::PurchaseOnlineService.run(
            online_service_customer_relation: relation,
            online_service_customer_price: price,
            manual: true
          )
        end

      return_json_response(outcome, {
        redirect_to: customer_status_online_service_path(slug: params[:slug], encrypted_social_service_user_id: params[:encrypted_social_service_user_id], encrypted_customer_id: MessageEncryptor.encrypt(current_customer.id) )
      })
    end

    def change_card
      outcome = Customers::StoreStripeCustomer.run(
        customer: current_customer,
        authorize_token: params[:token],
        setup_intent_id: params[:setup_intent_id]
      )

      if outcome.invalid?
        # Check if this is a 3DS case requiring client-side action
        if outcome.errors.details.dig(:customer)&.any? { |error| error[:error] == :requires_action }
          customer_error = outcome.errors.details[:customer].find { |error| error[:error] == :requires_action }
          render json: {
            message: outcome.errors.full_messages.join(""),
            client_secret: customer_error[:client_secret],
            setup_intent_id: customer_error[:setup_intent_id]
          }, status: :unprocessable_entity
        else
          render json: {
            message: outcome.errors.full_messages.join("")
          }, status: :unprocessable_entity
        end
      else
        render json: {
          redirect_to: customer_status_online_service_path(slug: params[:slug], encrypted_social_service_user_id: params[:encrypted_social_service_user_id], encrypted_customer_id: MessageEncryptor.encrypt(current_customer.id))
        }
      end
    end
  end
end
