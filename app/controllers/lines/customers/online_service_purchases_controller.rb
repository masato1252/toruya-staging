# frozen_string_literal: true

class Lines::Customers::OnlineServicePurchasesController < Lines::CustomersController
  before_action :sale_page

  def new
  end

  def create
    outcome = Sales::OnlineServices::Purchase.run(
      sale_page: @sale_page,
      customer: current_customer
    )

    return_json_response(outcome)
  end

  private

  def sale_page
    @sale_page = SalePage.find_by(slug: params[:slug])
  end

  def current_owner
    @sale_page.user
  end
end
