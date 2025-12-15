# frozen_string_literal: true

class SalePagesController < ActionController::Base
  include ProductLocale

  layout "booking"

  def show
    if !sale_page.user.subscription.active?
      render inline: t("common.no_service_warning_html")
      return
    end

    @main_product = sale_page.product

    case @main_product
    when BookingPage
      product = @main_product.primary_product
      @product_name = sale_page.product_name

      @keywords =
        [
          @product_name,
          @main_product.shop.display_name,
          @main_product.title,
          @main_product.greeting&.squish,
          @main_product.shop.company_full_address
      ].compact

      # Use SalePage's selling period instead of BookingPage's period for CTA control
      @is_started = sale_page.started?
      @is_ended = sale_page.ended?
      @company = @main_product.shop
      @payable = true
    when OnlineService
      @product_name = @main_product.name

      company_info = CompanyInfoSerializer.new(@main_product.company).attributes_hash

      @keywords = [
        @product_name,
        company_info["name"],
        @main_product.name,
        company_info["address"]
      ].compact

      @is_started = sale_page.started?
      @is_ended = sale_page.ended?
      @company = @main_product.company
      @payable = sale_page.payable?
    end
  end

  private

  def sale_page
    @sale_page ||= SalePage.active.find_by(slug: params[:slug]) || SalePage.active.find(params[:slug])
  end

  def product_social_user
    sale_page.user.social_user
  end
end
