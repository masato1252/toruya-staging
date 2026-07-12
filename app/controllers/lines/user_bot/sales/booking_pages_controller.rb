# frozen_string_literal: true

class Lines::UserBot::Sales::BookingPagesController < Lines::UserBotDashboardController
  def new
    if compat_read_data_plane?
      render :new_compat
      return
    end

    @sale_templates = SaleTemplate.where(locale: Current.business_owner.locale).order("id")

    if sale_page = SalePage.find_by(id: params[:sale_page_id])
      @selected_booking_page = BookingPageSerializer.new(sale_page.product).attributes_hash
      @selected_template = sale_page.sale_template.attributes.slice("id", "edit_body", "view_body")
      @sale_page = sale_page.serializer.attributes_hash
    elsif booking_page = BookingPage.find_by(slug: params[:booking_page_id]) || BookingPage.find_by(id: params[:booking_page_id])
      @selected_booking_page = BookingPageSerializer.new(booking_page).attributes_hash
    end
  end

  def create
    if compat_read_data_plane?
      return render_compat_sale_creation(
        "/lines/user_bot/owner/#{compat_sale_owner_id}/sales/booking_pages"
      )
    end

    outcome = ::Sales::BookingPages::Create.run(
      user: Current.business_owner,
      id: params[:id],
      selected_booking_page: params[:selected_booking_page],
      selected_template: params[:selected_template],
      template_variables: params[:template_variables]&.permit!.to_h,
      product_content: params[:product_content].permit!.to_h.transform_values! { |v| v.presence },
      staff: params[:selected_staff]&.permit!&.to_h,
      flow: params[:flow],
      draft: params[:draft]
    )

    return_json_response(outcome, { sale_page_id: outcome.result&.slug, redirect_to: lines_user_bot_sales_path })
  end

  private

  def compat_sale_owner_id
    resolve_compat_owner_id(nil) || resolve_compat_current_user_id(nil)
  end

  def render_compat_sale_creation(path)
    response = compat_v1_post_response(path, compat_sale_creation_payload)
    return render json: { status: "failed", error_message: "販売ページの保存に失敗しました" }, status: :bad_gateway unless response

    render json: response[:body], status: response[:status]
  end

  def compat_sale_creation_payload
    params.to_unsafe_h.except(
      "action",
      "authenticity_token",
      "business_owner_id",
      "commit",
      "controller",
      "format",
      "utf8"
    )
  end
end
