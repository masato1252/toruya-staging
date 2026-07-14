# frozen_string_literal: true

module OnlineServices
  class CustomerPaymentsController < ::OnlineServicesController
    def new
      if compat_read_data_plane?
        customer_id = cookies[:verified_customer_id] || cookies[:booking_customer_id]
        context = customer_id.present? ? compat_fetch_v1_json(
          "/online_services/#{params[:slug]}/customer_payments/page_context",
          customer_id: customer_id,
          order_id: params[:order_id]
        )&.dig("data") : nil
        if context && compat_public_read_for_owner?(context["owner_user_id"])
          @compat_customer_payment = context
          render :new_compat
          return
        end
      end

      @force_legacy_online_service = true
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
      if compat_public_read_for_owner?(online_service.user_id)
        customer = current_customer
        unless customer
          render json: { status: "failed", error_message: "顧客情報が見つかりません" }, status: :unprocessable_entity
          return
        end

        response = compat_v1_post_response(
          "/online_services/#{params[:slug]}/customer_payments",
          {
            customer_id: customer.id,
            social_service_user_id: current_social_customer&.social_user_id,
            encrypted_customer_id: params[:encrypted_customer_id],
            encrypted_social_service_user_id: params[:encrypted_social_service_user_id],
            token: params[:token],
            payment_intent_id: params[:payment_intent_id],
            setup_intent_id: params[:setup_intent_id],
            stripe_subscription_id: params[:stripe_subscription_id],
            order_id: params[:order_id]
          }.compact
        )

        unless response
          render json: { status: "failed", error_message: "決済に失敗しました" }, status: :bad_gateway
          return
        end

        render json: response[:body], status: response[:status]
        return
      end

      relation = online_service.online_service_customer_relations.where(customer: current_customer).last

      store_outcome = nil
      outcome =
        if online_service.recurring_charge_required?
          store_outcome = Customers::StoreStripeCustomer.run(
            customer: relation.customer,
            authorize_token: params[:token],
            stripe_subscription_id: params[:stripe_subscription_id],
            setup_intent_id: params[:setup_intent_id]
          )

          if store_outcome.valid?
            CustomerPayments::SubscribeOnlineService.run(
              online_service_customer_relation: relation,
              stripe_subscription_id: params[:stripe_subscription_id],
              payment_method_id: store_outcome.result
            )
          else
            store_outcome
          end
        else
          store_outcome = Customers::StoreStripeCustomer.run(
            customer: relation.customer,
            authorize_token: params[:token],
            payment_intent_id: params[:payment_intent_id],
            setup_intent_id: params[:setup_intent_id]
          )

          if store_outcome.valid?
            price = relation.price_details.find { |price| price.order_id == params[:order_id] } || relation.price_details.first

            CustomerPayments::PurchaseOnlineService.run(
              online_service_customer_relation: relation,
              online_service_customer_price: price,
              payment_intent_id: params[:payment_intent_id],
              payment_method_id: store_outcome.result,
              manual: true
            )
          else
            store_outcome
          end
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
      if compat_public_read_for_owner?(online_service.user_id)
        customer = current_customer
        social_customer = current_social_customer
        unless customer
          render json: { message: "顧客情報が見つかりません" }, status: :unprocessable_entity
          return
        end

        response = compat_v1_put_response(
          "/online_services/#{params[:slug]}/customer_payments/change_card",
          {
            customer_id: customer.id,
            social_service_user_id: social_customer&.social_user_id,
            encrypted_customer_id: params[:encrypted_customer_id],
            token: params[:token],
            setup_intent_id: params[:setup_intent_id]
          }.compact
        )

        unless response
          render json: { message: "カード情報の更新に失敗しました" }, status: :unprocessable_entity
          return
        end

        render json: response[:body], status: response[:status]
        return
      end

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
