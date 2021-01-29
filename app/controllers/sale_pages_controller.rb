class SalePagesController < ActionController::Base
  layout "booking"

  def show
    @sale_page ||= SalePage.find_by(slug: params[:id]) || SalePage.find(params[:id])
    @main_product = @sale_page.product

    product = @main_product.booking_options.order(amount_cents: :asc).first
    @product_name = product.display_name.presence || product.name.presence
  end
end
