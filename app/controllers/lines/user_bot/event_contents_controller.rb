# frozen_string_literal: true

class Lines::UserBot::EventContentsController < Lines::UserBotDashboardController
  before_action :redirect_to_admin, unless: :compat_read_enabled?

  def new
    if compat_read_data_plane?
      render :new_compat
      return
    end
  end

  def create
    return redirect_to_admin unless compat_read_data_plane?

    owner_id = resolve_compat_owner_id(nil) || resolve_compat_current_user_id(nil)
    result = compat_v1_post(
      "/lines/user_bot/owner/#{owner_id}/events/#{params[:event_id]}/event_contents",
      event_content_params
    )
    render json: result || { status: "failed", error_message: "イベントコンテンツを作成できませんでした" },
           status: (result&.dig("status") == "successful" ? :ok : :unprocessable_entity)
  end

  def show
    if compat_read_data_plane?
      render :show_compat
      return
    end
  end

  def edit
    if compat_read_data_plane?
      render :edit_compat
      return
    end
  end

  def update
    return redirect_to_admin unless compat_read_data_plane?

    owner_id = resolve_compat_owner_id(nil) || resolve_compat_current_user_id(nil)
    result = compat_v1_put(
      "/lines/user_bot/owner/#{owner_id}/event_contents/#{params[:id]}",
      event_content_params
    )
    render json: result || { status: "failed", error_message: "イベントコンテンツを更新できませんでした" },
           status: (result&.dig("status") == "successful" ? :ok : :unprocessable_entity)
  end

  def destroy
    return redirect_to_admin unless compat_read_data_plane?

    owner_id = resolve_compat_owner_id(nil) || resolve_compat_current_user_id(nil)
    result = compat_v1_delete("/lines/user_bot/owner/#{owner_id}/event_contents/#{params[:id]}")

    if result&.dig("status") == "successful"
      redirect_to lines_user_bot_events_path(business_owner_id: owner_id),
                  notice: I18n.t("common.delete_successfully_message")
    else
      redirect_to lines_user_bot_event_content_path(business_owner_id: owner_id, id: params[:id]),
                  alert: result&.dig("error_message")
    end
  end
  def upload_image; end
  def destroy_image; end
  def shops_by_user; end
  def online_services_for_shop; end

  private

  def event_content_params
    params.permit(
      :event_id, :shop_id, :online_service_id, :content_type, :title,
      :description, :introduction, :start_at, :end_at, :capacity, :position,
      :pre_ad_video_url, :post_ad_video_url, :direct_download_url,
      :upsell_booking_page_id, :upsell_booking_enabled, :monitor_enabled,
      :monitor_name, :monitor_price, :monitor_limit, :monitor_form_url
    ).to_h
  end

  def redirect_to_admin
    redirect_to admin_events_path, notice: "イベント管理はAdmin画面に移動しました"
  end
end
