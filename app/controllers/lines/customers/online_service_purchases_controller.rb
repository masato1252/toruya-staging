# frozen_string_literal: true

class Lines::Customers::OnlineServicePurchasesController < Lines::CustomersController
  before_action :sale_page

  def new
  end

  def create
    outcome = Sales::OnlineServices::Purchase.run(
      sale_page: @sale_page,
      customer: current_customer,
      authenticity_token: params[:token]
    )

    return_json_response(outcome, { redirect_to: new_lines_customers_online_service_purchases_path(slug: params[:slug]) })
  end

  private

  def sale_page
    @sale_page = SalePage.find_by(slug: params[:slug])
  end

  def current_owner
    @sale_page.user
  end
end
