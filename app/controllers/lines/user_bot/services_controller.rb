class Lines::UserBot::ServicesController < Lines::UserBotDashboardController
  VIDEO_SOLUTION = {
    key: "video",
    name: "video",
    description: "solution_description",
    enabled: true
  }
  GOALS = [
    {
      key: "name1",
      name: "name1",
      description: "description1",
      enabled: true,
      solutions: [
        VIDEO_SOLUTION
      ]
    },
    {
      key: "name2",
      name: "name2",
      description: "description2",
      enabled: true,
      solutions: [
        VIDEO_SOLUTION
      ]
    }
  ]
  def new
    # @sale_templates = SaleTemplate.all
    # if booking_page = BookingPage.find_by(id: params[:booking_page_id])
    #   @selected_booking_page = BookingPageSerializer.new(booking_page).attributes_hash
    # end
  end

  def create
    outcome = ::OnlineServices::Create.run(
      user: current_user,
      name: params[:name],
      selected_goal: params[:selected_goal],
      selected_solution: params[:selected_solution],
      end_time: params[:end_time].permit!.to_h,
      upsell: params[:upsell].permit!.to_h,
      content: params[:content].permit!.to_h,
      selected_company: params[:selected_company].permit!.to_h,
    )

    return_json_response(outcome, { online_service_id: outcome.result&.id })
  end
end
