class Lines::UserBot::CustomMessagesController < Lines::UserBotDashboardController
  def update
    service = params[:service_type].constantize.find_by(user: current_user, id: params[:service_id])

    if params[:id]
      outcome = CustomMessages::Customers::Update.run(
        message: CustomMessage.find_by!(id: params[:id], service: service),
        template: params[:template],
        after_days: params[:after_days].presence
      )
    else
      outcome = CustomMessages::Customers::Create.run(
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

    message =
      if params[:id]
        CustomMessages::Customers::Update.run!(
          message: CustomMessage.find_by!(id: params[:id], service: service),
          template: params[:template],
          after_days: params[:after_days].presence
        )
      else
        CustomMessages::Customers::Create.run!(
          service: service,
          scenario: params[:scenario],
          template: params[:template],
          after_days: params[:after_days].presence
        )
      end
    message.demo_message_for_owner

    head :ok
  end

  def destroy
    service = params[:service_type].constantize.find_by(user: current_user, id: params[:service_id])
    message = CustomMessage.find_by!(id: params[:id], service: service)

    message.destroy
    redirect_path =
      case service
      when OnlineService
        lines_user_bot_service_custom_messages_path(params[:service_id])
      when BookingPage
        lines_user_bot_booking_page_custom_messages_path(params[:service_id])
      end

    redirect_to redirect_path
  end
end
