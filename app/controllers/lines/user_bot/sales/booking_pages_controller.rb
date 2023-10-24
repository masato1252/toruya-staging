# frozen_string_literal: true

class Lines::UserBot::Sales::BookingPagesController < Lines::UserBotDashboardController
  def new
    @sale_templates = SaleTemplate.all.order("id")
    if booking_page = BookingPage.find_by(slug: params[:booking_page_id]) || BookingPage.find_by(id: params[:booking_page_id])
      @selected_booking_page = BookingPageSerializer.new(booking_page).attributes_hash
    end
  end

  def create
    outcome = ::Sales::BookingPages::Create.run(
      user: Current.business_owner,
      selected_booking_page: params[:selected_booking_page],
      selected_template: params[:selected_template],
      template_variables: params[:template_variables].permit!.to_h,
      product_content: params[:product_content].permit!.to_h,
      staff: params[:selected_staff].permit!.to_h,
      flow: params[:flow]
    )

    return_json_response(outcome, { sale_page_id: outcome.result&.slug })
  end
end
