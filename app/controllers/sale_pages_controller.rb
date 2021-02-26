# frozen_string_literal: true

class SalePagesController < ActionController::Base
  layout "booking"

  def show
    @sale_page ||= SalePage.find_by(slug: params[:slug]) || SalePage.find(params[:slug])
    @main_product = @sale_page.product

    case @main_product
    when BookingPage
      product = @main_product.booking_options.order(amount_cents: :asc).first
      @product_name = product.display_name.presence || product.name.presence

      @keywords =
        [
          @product_name,
          @main_product.shop.display_name,
          @main_product.title,
          @main_product.greeting&.squish,
          @main_product.shop.address
      ].compact

      @serializer = SalePages::BookingPageSerializer
    when OnlineService
      @product_name = @main_product.name

      company_info = CompanyInfoSerializer.new(@main_product.company).attributes_hash

      @keywords = [
        @product_name,
        company_info["name"],
        @main_product.name,
        company_info["address"]
      ].compact

      @serializer = SalePages::OnlineServiceSerializer
    end
  end
end
