class Lines::UserBot::CustomMessagesController < Lines::UserBotDashboardController
  def update
    service = params[:service_type].constantize.find_by(user: current_user, id: params[:service_id])

    if params[:id]
      outcome = CustomMessages::Update.run(
        message: CustomMessage.find_by!(id: params[:id], service: service),
        template: params[:template],
        after_days: params[:after_days].presence
      )
    else
      outcome = CustomMessages::Create.run(
        service: service,
        scenario: params[:scenario],
        template: params[:template],
        after_days: params[:after_days].presence
      )
    end

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

    message = CustomMessages::Update.run!(
      service: service,
      template: params[:template],
      scenario: params[:scenario],
      position: params[:position],
      after_last_message_days: params[:after_last_message_days],
    )
    message.demo_message_for_owner

    head :ok
  end
end
