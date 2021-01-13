class Lines::UserBot::ServicesController < Lines::UserBotDashboardController
  def new
    # @sale_templates = SaleTemplate.all
    # if booking_page = BookingPage.find_by(id: params[:booking_page_id])
    #   @selected_booking_page = BookingPageSerializer.new(booking_page).attributes_hash
    # end
  end

  def create
    # outcome = ::Sales::BookingPages::Create.run(
    #   user: current_user,
    #   selected_booking_page: params[:selected_booking_page],
    #   selected_template: params[:selected_template],
    #   template_variables: params[:template_variables].permit!.to_h,
    #   product_content: params[:product_content].permit!.to_h,
    #   staff: params[:selected_staff].permit!.to_h,
    #   flow: params[:flow]
    # )
    #
    # return_json_response(outcome, { sale_page_id: outcome.result&.id })
  end
end
