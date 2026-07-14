# frozen_string_literal: true

class SalePagesController < ActionController::Base
  include ProductLocale
  include CompatSession

  layout "booking"

  def show
    if compat_read_data_plane?
      response = compat_fetch_v1_json("/sale_pages/#{params[:slug]}/page_context")
      data = response&.dig("data")
      if data && compat_public_read_for_owner?(data["owner_user_id"])
        unless response.dig("includes", "subscription_active")
          render inline: t("common.no_service_warning_html")
          return
        end
        @compat_sale_page = data
        @compat_sale_page_meta = response.dig("includes", "meta") || {}
        render :show_api_compat
        return
      end
    end

    unless subscription_active_for_public_sale?(sale_page)
      render inline: t("common.no_service_warning_html")
      return
    end

    load_sale_page_view_context

    if compat_public_read_for_owner?(sale_page.user_id)
      render :show_compat
      return
    end
  end

  private

  def load_sale_page_view_context
    @main_product = sale_page.product

    case @main_product
    when BookingPage
      @product_name = sale_page.product_name
      @keywords =
        [
          @product_name,
          @main_product.shop.display_name,
          @main_product.title,
          @main_product.greeting&.squish,
          @main_product.shop.company_full_address
        ].compact
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
      @company = @main_product.company
      @payable = sale_page.payable?
    end

    # SalePage controls the selling period for both product kinds.
    @is_started = sale_page.started?
    @is_ended = sale_page.ended?
  end

  def sale_page
    @sale_page ||= SalePage.active.find_by(slug: params[:slug]) || SalePage.active.find(params[:slug])
  end

  def product_social_user
    sale_page.user.social_user
  end
end
