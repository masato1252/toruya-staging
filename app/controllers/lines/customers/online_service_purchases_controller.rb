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
      authorize_token: params[:token]
    )

    return_json_response(outcome, { redirect_to: @sale_page.external? ? @sale_page.product.content_url : new_lines_customers_online_service_purchases_path(slug: params[:slug]) })
  end

  private

  def sale_page
    @sale_page = SalePage.find_by(slug: params[:slug])
  end

  def current_owner
    @sale_page.user
  end
end
