# frozen_string_literal: true

class Lines::UserBot::Services::LessonsController < Lines::UserBotDashboardController
  include CrossAccountRedirect
  redirect_to_correct_owner_for :online_services, param_key: :service_id

  def new
    if compat_read_data_plane?
      render :new_compat
      return
    end

    @online_service = Current.business_owner.online_services.find(params[:service_id])
    chapter = @online_service.chapters.find(params[:chapter_id])
    @lesson = chapter.lessons.new
  end

  def create
    if compat_read_data_plane?
      return proxy_compat_lesson(
        :post,
        "/chapters/#{params[:chapter_id]}/lessons"
      )
    end

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

    return_json_response(outcome, { redirect_to: lines_user_bot_service_chapters_path(params[:service_id], business_owner_id: params[:business_owner_id]) })
  end

  def show
    if compat_read_data_plane?
      render :show_compat
      return
    end

    @online_service = Current.business_owner.online_services.find(params[:service_id])
    @chapter = @online_service.chapters.find(params[:chapter_id])
    @lesson = @chapter.lessons.find(params[:id])
    @course_hash = CourseSerializer.new(@online_service, { params: { is_owner: true }}).attributes_hash
  end

  def edit
    if compat_read_data_plane?
      render :edit_compat
      return
    end

    @online_service = Current.business_owner.online_services.find(params[:service_id])
    chapter = @online_service.chapters.find(params[:chapter_id])
    @lesson = chapter.lessons.find(params[:id])
    @attribute = params[:attribute]
  end

  def update
    return proxy_compat_lesson(:put, "/lessons/#{params[:id]}") if compat_read_data_plane?

    lesson = Lesson.find(params[:id])

    outcome = ::Lessons::Update.run(lesson: lesson, attrs: params.permit!.to_h, update_attribute: params[:attribute])

    return_json_response(outcome, { redirect_to: lines_user_bot_service_chapter_lesson_path(params[:service_id], params[:chapter_id], params[:id], anchor: params[:attribute], business_owner_id: params[:business_owner_id]) })
  end

  def destroy
    if compat_read_data_plane?
      owner_id = resolve_compat_owner_id(nil) || resolve_compat_current_user_id(nil)
      result = compat_v1_delete(
        "/lines/user_bot/owner/#{owner_id}/services/#{params[:service_id]}/lessons/#{params[:id]}"
      )

      if result&.dig("status") != "successful"
        flash[:alert] = result&.dig("error_message") || I18n.t("common.operation_failed", default: "削除に失敗しました")
      end
      redirect_to lines_user_bot_service_chapters_path(params[:service_id], business_owner_id: owner_id)
      return
    end

    lesson = Lesson.find(params[:id])

    lesson.destroy!

    redirect_to lines_user_bot_service_chapters_path(params[:service_id], business_owner_id: params[:business_owner_id])
  end

  private

  def proxy_compat_lesson(method, suffix)
    owner_id = resolve_compat_owner_id(nil) || resolve_compat_current_user_id(nil)
    path = "/lines/user_bot/owner/#{owner_id}/services/#{params[:service_id]}#{suffix}"
    body = params.permit!.to_h.merge(chapter_id: params[:chapter_id])
    result = method == :post ? compat_v1_post(path, body) : compat_v1_put(path, body)
    render json: result || { status: "failed", error_message: "レッスンを保存できませんでした" },
           status: result ? :ok : :bad_gateway
  end
end
