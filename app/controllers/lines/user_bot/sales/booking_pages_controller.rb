# frozen_string_literal: true

class Lines::UserBot::Sales::BookingPagesController < Lines::UserBotDashboardController
  def new
    @sale_templates = SaleTemplate.all.order("id")

    if sale_page = SalePage.find_by(id: params[:sale_page_id])
      @selected_booking_page = BookingPageSerializer.new(sale_page.product).attributes_hash
      @selected_template = sale_page.sale_template.attributes.slice("id", "edit_body", "view_body")
      @sale_page = sale_page.serializer.attributes_hash
    elsif booking_page = BookingPage.find_by(slug: params[:booking_page_id]) || BookingPage.find_by(id: params[:booking_page_id])
      @selected_booking_page = BookingPageSerializer.new(booking_page).attributes_hash
    end
  end

  def create
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
end
