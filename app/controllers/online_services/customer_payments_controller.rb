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
          @relation.price_details.find { |price| price.order_id == params[:order_id] } || @relation.price_details.first
        end
    end

    def create
      relation = online_service.online_service_customer_relations.where(customer: current_customer).last

      outcome =
        if online_service.recurring_charge_required?
          customer_outcome = Customers::StoreStripeCustomer.run(
            customer: relation.customer,
            authorize_token: params[:token],
            stripe_subscription_id: params[:stripe_subscription_id]
          )

          CustomerPayments::SubscribeOnlineService.run(
            online_service_customer_relation: relation,
            stripe_subscription_id: params[:stripe_subscription_id],
            payment_method_id: params[:token]
          )
        else
          customer_outcome = Customers::StoreStripeCustomer.run(
            customer: relation.customer,
            authorize_token: params[:token],
            payment_intent_id: params[:payment_intent_id]
          )

          price = relation.price_details.find { |price| price.order_id == params[:order_id] } || relation.price_details.first

          CustomerPayments::PurchaseOnlineService.run(
            online_service_customer_relation: relation,
            online_service_customer_price: price,
            payment_intent_id: params[:payment_intent_id],
            payment_method_id: params[:token],
            manual: true
          )
        end

      if outcome.valid?
        render json: {
          status: "successful",
          redirect_to: customer_status_online_service_path(slug: params[:slug], encrypted_social_service_user_id: params[:encrypted_social_service_user_id], encrypted_customer_id: MessageEncryptor.encrypt(current_customer.id))
        }
      else
        # Check if it's a 3DS-related error - any error containing client_secret needs frontend handling
        error_with_client_secret = find_error_with_client_secret(outcome)

        if error_with_client_secret
          response_data = {
            status: "requires_action",
            client_secret: error_with_client_secret[:client_secret],
            setup_intent_id: error_with_client_secret[:setup_intent_id],
            payment_intent_id: error_with_client_secret[:payment_intent_id],
            stripe_subscription_id: error_with_client_secret[:stripe_subscription_id]
          }

          render json: response_data
        else
          Rollbar.error("#{outcome.class} service failed", {
            errors: outcome.errors.details,
            params: params
          })

          render json: {
            status: "failed",
            error_message: outcome.errors.full_messages.join(", ")
          }, status: :bad_request
        end
      end
    end

    def change_card
      outcome = Customers::StoreStripeCustomer.run(
        customer: current_customer,
        authorize_token: params[:token],
        setup_intent_id: params[:setup_intent_id]
      )

      if outcome.invalid?
                # Check if this is a 3DS case requiring client-side action
        error_with_client_secret = find_error_with_client_secret(outcome)

        if error_with_client_secret
          render json: {
            message: outcome.errors.full_messages.join(""),
            client_secret: error_with_client_secret[:client_secret],
            setup_intent_id: error_with_client_secret[:setup_intent_id]
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
