# frozen_string_literal: true

class Lines::UserBot::Services::CustomMessagesController < Lines::UserBotDashboardController
  def index
    @online_service = current_user.online_services.find(params[:service_id])
    @sequence_messages = CustomMessage.where(service: @online_service, scenario: CustomMessage::ONLINE_SERVICE_PURCHASED).order("after_days ASC NULLS FIRST")
  end

  def edit_scenario
    @online_service = current_user.online_services.find(params[:service_id])
    @message = CustomMessage.find_by(service: @online_service, id: params[:id])
    @template = @message ? @message.content : CustomMessage.template_of(@online_service, params[:scenario])
  end

  def update_scenario
    online_service = current_user.online_services.find(params[:service_id])

    if params[:id]
      outcome = CustomMessages::Update.run(
        custom_message: CustomMessage.find_by!(id: params[:id], service: online_services),
        template: params[:template],
        after_days: params[:after_days]
      )
    else
      outcome = CustomMessages::Create.run(
        service: online_services,
        scenario: params[:scenario],
        template: params[:template],
        after_days: params[:after_days]
      )
    end

    return_json_response(outcome, { redirect_to: lines_user_bot_service_custom_messages_path(params[:service_id]) })
  end

  def demo
    online_service = current_user.online_services.find(params[:service_id])

    message = CustomMessages::Update.run!(
      service: online_service,
      template: params[:template],
      scenario: params[:scenario]
    )
    message.demo_message_for_owner

    head :ok
  end
end
