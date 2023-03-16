# frozen_string_literal: true

class Lines::UserBot::Services::LessonsController < Lines::UserBotDashboardController
  def new
    @online_service = Current.business_owner.online_services.find(params[:service_id])
    chapter = @online_service.chapters.find(params[:chapter_id])
    @lesson = chapter.lessons.new
  end

  def create
    online_service = Current.business_owner.online_services.find(params[:service_id])
    chapter = online_service.chapters.find(params[:chapter_id])

    outcome = ::Lessons::Create.run(
      chapter: chapter,
      name: params[:name],
      content_url: params[:content_url],
      note: params[:note],
      solution_type: params[:selected_solution],
      start_time: params[:start_time].permit!.to_h
    )

    return_json_response(outcome, { redirect_to: lines_user_bot_service_chapters_path(params[:service_id]) })
  end

  def show
    @online_service = Current.business_owner.online_services.find(params[:service_id])
    @chapter = @online_service.chapters.find(params[:chapter_id])
    @lesson = @chapter.lessons.find(params[:id])
    @course_hash = CourseSerializer.new(@online_service, { params: { is_owner: true }}).attributes_hash
  end

  def edit
    @online_service = Current.business_owner.online_services.find(params[:service_id])
    chapter = @online_service.chapters.find(params[:chapter_id])
    @lesson = chapter.lessons.find(params[:id])
    @attribute = params[:attribute]
  end

  def update
    lesson = Lesson.find(params[:id])

    outcome = ::Lessons::Update.run(lesson: lesson, attrs: params.permit!.to_h, update_attribute: params[:attribute])

    return_json_response(outcome, { redirect_to: lines_user_bot_service_chapter_lesson_path(params[:service_id], params[:chapter_id], params[:id], anchor: params[:attribute]) })
  end

  def destroy
    lesson = Lesson.find(params[:id])

    lesson.destroy!

    redirect_to lines_user_bot_service_chapters_path(params[:service_id])
  end
end
