# frozen_string_literal: true

class Lines::UserBot::Services::ChaptersController < Lines::UserBotDashboardController
  include CrossAccountRedirect
  redirect_to_correct_owner_for :online_services, param_key: :service_id

  def index
    if compat_read_data_plane?
      render :index_compat
      return
    end

    @online_service = Current.business_owner.online_services.find(params[:service_id])
    @course_hash = CourseSerializer.new(@online_service, { params: { is_owner: true }}).attributes_hash
  end

  def new
    if compat_read_data_plane?
      render :edit_compat
      return
    end

    @online_service = Current.business_owner.online_services.find(params[:service_id])
    @chapter = @online_service.chapters.new

    render action: :edit
  end

  def edit
    if compat_read_data_plane?
      render :edit_compat
      return
    end

    @online_service = Current.business_owner.online_services.find(params[:service_id])
    @chapter = @online_service.chapters.find(params[:id])
  end

  def create
    return proxy_compat_chapter(:post, "/chapters") if compat_read_data_plane?

    online_service = Current.business_owner.online_services.find(params[:service_id])

    outcome = Chapters::Create.run(
      online_service: online_service,
      name: params[:name]
    )

    return_json_response(outcome, { redirect_to: lines_user_bot_service_chapters_path(params[:service_id], business_owner_id: params[:business_owner_id]) })
  end

  def update
    return proxy_compat_chapter(:put, "/chapters/#{params[:id]}") if compat_read_data_plane?

    online_service = Current.business_owner.online_services.find(params[:service_id])
    chapter = online_service.chapters.find(params[:id])

    outcome = Chapters::Update.run(
      chapter: chapter,
      name: params[:name]
    )

    return_json_response(outcome, { redirect_to: lines_user_bot_service_chapters_path(params[:service_id], business_owner_id: params[:business_owner_id]) })
  end

  def destroy
    if compat_read_data_plane?
      owner_id = resolve_compat_owner_id(nil) || resolve_compat_current_user_id(nil)
      result = compat_v1_delete(
        "/lines/user_bot/owner/#{owner_id}/services/#{params[:service_id]}/chapters/#{params[:id]}"
      )

      if result&.dig("status") != "successful"
        flash[:alert] = result&.dig("error_message") || I18n.t("common.operation_failed", default: "削除に失敗しました")
      end
      redirect_to lines_user_bot_service_chapters_path(params[:service_id], business_owner_id: owner_id)
      return
    end

    online_service = Current.business_owner.online_services.find(params[:service_id])
    chapter = online_service.chapters.find(params[:id])

    outcome = Chapters::Delete.run(chapter: chapter)

    if outcome.invalid?
      flash[:alert] = outcome.errors.full_messages.join(", ")
    end

    redirect_to lines_user_bot_service_chapters_path(params[:service_id], business_owner_id: params[:business_owner_id])
  end

  def reorder
    return proxy_compat_chapter(:put, "/chapters/reorder") if compat_read_data_plane?

    # {
    #   "items" => [
    #     {
    #       "chapter_id" => "chapter_15",
    #       "id" => 15,
    #       "lessons" => [
    #         31,
    #         30,
    #         32
    #       ]
    #     },
    #   ],
    #   "service_id" => "148",
    # }
    outcome = Chapters::Reorder.run(
      online_service: Current.business_owner.online_services.find(params[:service_id]),
      items: params.permit!.to_h[:items]
    )

    return_json_response(outcome, { redirect_to: lines_user_bot_service_chapters_path(params[:service_id], business_owner_id: params[:business_owner_id]) })
  end

  private

  def proxy_compat_chapter(method, suffix)
    owner_id = resolve_compat_owner_id(nil) || resolve_compat_current_user_id(nil)
    path = "/lines/user_bot/owner/#{owner_id}/services/#{params[:service_id]}#{suffix}"
    result = method == :post ? compat_v1_post(path, params.permit!.to_h) : compat_v1_put(path, params.permit!.to_h)
    render json: result || { status: "failed", error_message: "チャプターを保存できませんでした" },
           status: result ? :ok : :bad_gateway
  end
end
