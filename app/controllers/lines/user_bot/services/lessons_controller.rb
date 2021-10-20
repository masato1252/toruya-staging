# frozen_string_literal: true

class Lines::UserBot::Services::LessonsController < Lines::UserBotDashboardController
  def new
    @online_service = current_user.online_services.find(params[:service_id])
    chapter = @online_service.chapters.find(params[:chapter_id])
    @lesson = chapter.lessons.new
  end

  def create
    online_service = current_user.online_services.find(params[:service_id])
    chapter = online_service.chapters.find(params[:chapter_id])

    outcome = Lessons::Create.run(
      chapter: chapter,
      name: params[:name],
      content: params[:content]&.permit!&.to_h,
      note: params[:note],
      solution_type: params[:selected_solution]
    )

    return_json_response(outcome, { redirect_to: lines_user_bot_service_chapters_path(params[:service_id]) })
  end
end
