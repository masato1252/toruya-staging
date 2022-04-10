# frozen_string_literal: true

class Lines::Customers::OnlineServicePurchasesController < Lines::CustomersController
  before_action :sale_page
  skip_before_action :track_ahoy_visit

  def new
    @relation =
      if current_customer
        product = sale_page.product
        product.online_service_customer_relations.find_by(online_service: product, customer: current_customer)
      end
  end

  def create
    outcome = Sales::OnlineServices::Purchase.run(
      sale_page: @sale_page,
      customer: current_customer,
      authorize_token: params[:token],
      payment_type: params[:payment_type]
    )

    if outcome.valid?
      return_json_response(outcome, { redirect_to: @sale_page.external? ? @sale_page.product.content_url : sale_page_path(slug: params[:slug]) })
    else
      Rollbar.error("Sales::OnlineServices::Purchase failed", {
        errors: outcome.errors.details,
        params: params
      })
      return_json_response(outcome, { redirect_to: @sale_page.external? ? @sale_page.product.content_url : new_lines_customers_online_service_purchases_path(slug: params[:slug], payment_type: params[:payment_type]) })
    end
  end

  private

  def sale_page
    @sale_page = SalePage.find_by!(slug: params[:slug])
  end

  def current_owner
    @sale_page.user
  end
end
