# frozen_string_literal: true

class Lines::UserBot::Services::Episodes::CustomMessagesController < Lines::UserBotDashboardController
  def index
    @online_service = Current.business_owner.online_services.find(params[:service_id])
    @episode = @online_service.episodes.find(params[:episode_id])
    scope = CustomMessage.scenario_of(@episode, CustomMessages::Customers::Template::EPISODE_WATCHED)
    @watched_message = scope.right_away.first
  end

  def edit_scenario
    @online_service = Current.business_owner.online_services.find(params[:service_id])
    @episode = @online_service.episodes.find(params[:episode_id])
    @message = CustomMessage.find_by(service: @episode, id: params[:id])
    @template = @message&.content || ""
  end
end
