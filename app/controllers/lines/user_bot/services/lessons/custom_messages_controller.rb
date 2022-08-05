# frozen_string_literal: true

class Lines::UserBot::Services::Lessons::CustomMessagesController < Lines::UserBotDashboardController
  def index
    @online_service = current_user.online_services.find(params[:service_id])
    @chapter = @online_service.chapters.find(params[:chapter_id])
    @lesson = @chapter.lessons.find(params[:lesson_id])
    scope = CustomMessage.scenario_of(@lesson, CustomMessages::Customers::Template::LESSON_WATCHED)
    @watched_message = scope.right_away.first
  end

  def edit_scenario
    @online_service = current_user.online_services.find(params[:service_id])
    @chapter = @online_service.chapters.find(params[:chapter_id])
    @lesson = @chapter.lessons.find(params[:lesson_id])
    @message = CustomMessage.find_by!(service: @lesson, id: params[:id])
    @template = @message.content
  end
end
