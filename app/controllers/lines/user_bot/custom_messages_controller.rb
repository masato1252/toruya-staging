class Lines::UserBot::CustomMessagesController < Lines::UserBotDashboardController
  def update
    service = params[:service_type].constantize.find_by(user: current_user, id: params[:service_id])
    outcome = CustomMessages::Update.run(service: service , template: params[:template], scenario: params[:scenario])

    redirect_path =
      case service
      when OnlineService
        lines_user_bot_service_custom_messages_path(params[:service_id])
      when BookingPage
        lines_user_bot_booking_page_custom_messages_path(params[:service_id])
      end

    return_json_response(outcome, { redirect_to: redirect_path })
  end

  def demo
    service = params[:service_type].constantize.find_by(user: current_user, id: params[:service_id])

    message = CustomMessages::Update.run!(service: service, template: params[:template], scenario: params[:scenario])
    message.demo_message_for_owner

    head :ok
  end
end
