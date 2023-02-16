# frozen_string_literal: true

class Lines::UserBot::Services::EpisodesController < Lines::UserBotDashboardController
  def index
    @online_service = current_user.online_services.find(params[:service_id])
    @episodes = ::Episodes::Search.run!(online_service: @online_service, keyword: params[:keyword], available: false)
  end

  def show
    @online_service = current_user.online_services.find(params[:service_id])
    @episode = @online_service.episodes.find(params[:id])
    @membership_hash = MembershipSerializer.new(@online_service).attributes_hash
  end

  def new
    @online_service = current_user.online_services.find(params[:service_id])
    @episode = @online_service.episodes.new
  end

  def edit
    @online_service = current_user.online_services.find(params[:service_id])
    @episode = @online_service.episodes.find(params[:id])
    @attribute = params[:attribute]
  end

  def create
    online_service = current_user.online_services.find(params[:service_id])

    outcome = Episodes::Create.run(
      online_service: online_service,
      name: params[:name],
      content_url: params[:content_url],
      note: params[:note],
      solution_type: params[:selected_solution],
      start_time: params[:start_time].permit!.to_h,
      tags: params[:tags]
    )

    return_json_response(outcome, { redirect_to: lines_user_bot_service_episodes_path(params[:service_id]) })
  end

  def update
    online_service = current_user.online_services.find(params[:service_id])
    episode = online_service.episodes.find(params[:id])

    outcome = Episodes::Update.run(episode: episode, attrs: params.permit!.to_h, update_attribute: params[:attribute])

    return_json_response(outcome, { redirect_to: lines_user_bot_service_episode_path(params[:service_id], params[:id], anchor: params[:attribute]) })
  end

  def destroy
    online_service = current_user.online_services.find(params[:service_id])
    episode = online_service.episodes.find(params[:id])

    episode.destroy!

    redirect_to lines_user_bot_service_episodes_path(params[:service_id])
  end
end
