# frozen_string_literal: true

class Lines::Customers::OnlineServicePurchasesController < Lines::CustomersController
  include MixpanelHelper
  include ProductLocale
  before_action :sale_page
  skip_before_action :track_ahoy_visit, only: [:create]
  skip_before_action :verify_authenticity_token, only: [:create]
  before_action :tracking_from, only: [:new]

  def new
    if @sale_page.ended?
      redirect_to sale_page_path(slug: @sale_page.slug)
      return
    end

    @relation =
      if current_customer
        product = sale_page.product
        product.online_service_customer_relations.find_by(online_service: product, customer: current_customer)
      end

    if @relation
      # Redirect to the online service page
      redirect_to online_service_path(slug: product.slug)
      return
    end
  end

  def create
    if @sale_page.ended?
      render json: { status: "failed", redirect_to: sale_page_path(slug: @sale_page.slug) }
      return
    end

    outcome = Sales::OnlineServices::Purchase.run(
      sale_page: @sale_page,
      customer: current_customer,
      authorize_token: params[:token],
      payment_type: params[:payment_type],
      function_access_id: params[:function_access_id]
    )

    if outcome.invalid?
      Rollbar.error("Sales::OnlineServices::Purchase failed", {
        errors: outcome.errors.details,
        params: params
      })
    end

    return_json_response(outcome, { redirect_to: @sale_page.external? ? @sale_page.product.external_url : new_lines_customers_online_service_purchases_path(slug: params[:slug], payment_type: params[:payment_type]) })
  end

  private

  def sale_page
    @sale_page ||= SalePage.find_by!(slug: params[:slug])
  end

  def current_owner
    @sale_page ||= SalePage.find_by!(slug: params[:slug])
    @sale_page.user
  end

  def product_social_user
    sale_page.user.social_user
  end
end