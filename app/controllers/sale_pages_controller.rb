# frozen_string_literal: true

class SalePagesController < ActionController::Base
  layout "booking"

  def show
    @sale_page ||= SalePage.find_by(slug: params[:id]) || SalePage.find(params[:id])
    @main_product = @sale_page.product

    @product_name =
      case @main_product
      when BookingPage
        product = @main_product.booking_options.order(amount_cents: :asc).first
        product.display_name.presence || product.name.presence
      when OnlineService
        @main_product.name
      end

    @keywords =
      case @main_product
      when BookingPage
        [
          @product_name,
          @main_product.shop.display_name,
          @main_product.title,
          @main_product.greeting&.squish,
          @main_product.shop.address
        ].compact
      when OnlineService
        company_info = CompanyInfoSerializer.new(@main_product.company).attributes_hash

        [
          @product_name,
          company_info["name"],
          @main_product.name,
          company_info["address"]
        ].compact
      end

    @serializer =
      case @main_product
      when BookingPage
        BookingPageSalePageSerializer
      when OnlineService
        OnlineServiceSalePageSerializer
      end
  end
end
