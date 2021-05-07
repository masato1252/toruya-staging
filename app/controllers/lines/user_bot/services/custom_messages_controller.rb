# frozen_string_literal: true

class Lines::UserBot::Services::CustomMessagesController < Lines::UserBotDashboardController
  def index
    @online_service = current_user.online_services.find(params[:service_id])
  end

  def edit_scenario
    @online_service = current_user.online_services.find(params[:service_id])
    @template = CustomMessage.template_of(@online_service, params[:scenario])
  end

  def update_scenario
    online_service = current_user.online_services.find(params[:service_id])
    outcome = CustomMessages::Update.run(service: online_service, template: params[:template], scenario: params[:scenario])

    return_json_response(outcome, { redirect_to: lines_user_bot_service_custom_messages_path(params[:service_id]) })
  end

  def demo
    online_service = current_user.online_services.find(params[:service_id])

    message = CustomMessages::Update.run!(service: online_service, template: params[:template], scenario: params[:scenario])
    message.demo_message_for_owner

    head :ok
  end
end
