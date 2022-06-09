# frozen_string_literal: true

class Lines::UserBot::Services::CustomMessagesController < Lines::UserBotDashboardController
  def index
    @online_service = current_user.online_services.find(params[:service_id])
    scope = CustomMessage.scenario_of(@online_service, CustomMessages::Customers::Template::ONLINE_SERVICE_PURCHASED)
    @purchased_message = scope.right_away.first
    @sequence_messages = scope.sequence.order("after_days ASC")
  end

  def edit_scenario
    @online_service = current_user.online_services.find(params[:service_id])
    @message = CustomMessage.find_by(service: @online_service, id: params[:id])
    @template = @message ? @message.content : (params[:right_away] ? ::CustomMessages::Customers::Template.run!(product: @online_service, scenario: params[:scenario]) : "")
  end
end
