# frozen_string_literal: true

class Lines::UserBot::EventContentsController < Lines::UserBotDashboardController
  before_action :require_team_plan!
  before_action :set_event, only: [:new, :create]
  before_action :set_event_content, only: [:show, :edit, :update, :destroy, :upload_image, :destroy_image]

  def new
    @event_content = @event.event_contents.new
    @shops = Current.business_owner.shops.active
    @booking_pages = Current.business_owner.booking_pages.active rescue []
  end

  def create
    outcome = EventContents::Create.run(
      event: Event.undeleted.find(params[:event_id]),
      content_type: params[:content_type],
      title: params[:title],
      description: params[:description],
      introduction: params[:introduction],
      shop_id: params[:shop_id].presence,
      online_service_id: params[:online_service_id].presence,
      start_at: params[:start_at],
      end_at: params[:end_at],
      capacity: params[:capacity].presence,
      position: params[:position].presence || 0,
      pre_ad_video_url: params[:pre_ad_video_url],
      post_ad_video_url: params[:post_ad_video_url],
      direct_download_url: params[:direct_download_url],
      upsell_booking_page_id: params[:upsell_booking_page_id].presence,
      upsell_booking_enabled: params[:upsell_booking_enabled],
      monitor_enabled: params[:monitor_enabled],
      monitor_name: params[:monitor_name],
      monitor_price: params[:monitor_price].presence,
      monitor_limit: params[:monitor_limit].presence,
      monitor_form_url: params[:monitor_form_url],
      thumbnail: params[:thumbnail]
    )

    if outcome.valid?
      render json: { redirect_to: lines_user_bot_event_content_path(business_owner_id: business_owner_id, id: outcome.result.id) }
    else
      return_json_response(outcome, {})
    end
  end

  def show
    @event = @event_content.event
  end

  def edit
    @event = @event_content.event
    @shops = Current.business_owner.shops.active
    @booking_pages = Current.business_owner.booking_pages.active rescue []
    @online_services = @event_content.shop_id ? OnlineService.where(company_type: "Shop", company_id: @event_content.shop_id).not_deleted : []
  end

  def update
    outcome = EventContents::Update.run(
      event_content: @event_content,
      content_type: params[:content_type],
      title: params[:title],
      description: params[:description],
      introduction: params[:introduction],
      shop_id: params[:shop_id].presence,
      online_service_id: params[:online_service_id].presence,
      start_at: params[:start_at],
      end_at: params[:end_at],
      capacity: params[:capacity].presence,
      position: params[:position].presence || 0,
      pre_ad_video_url: params[:pre_ad_video_url],
      post_ad_video_url: params[:post_ad_video_url],
      direct_download_url: params[:direct_download_url],
      upsell_booking_page_id: params[:upsell_booking_page_id].presence,
      upsell_booking_enabled: params[:upsell_booking_enabled],
      monitor_enabled: params[:monitor_enabled],
      monitor_name: params[:monitor_name],
      monitor_price: params[:monitor_price].presence,
      monitor_limit: params[:monitor_limit].presence,
      monitor_form_url: params[:monitor_form_url],
      thumbnail: params[:thumbnail]
    )

    return_json_response(outcome, { redirect_to: lines_user_bot_event_content_path(business_owner_id: business_owner_id, id: @event_content.id) })
  end

  def destroy
    outcome = EventContents::Destroy.run(event_content: @event_content)

    if outcome.valid?
      redirect_to lines_user_bot_event_path(business_owner_id: business_owner_id, id: @event_content.event_id), notice: I18n.t("common.delete_successfully_message")
    else
      redirect_back(fallback_location: lines_user_bot_event_path(business_owner_id: business_owner_id, id: @event_content.event_id))
    end
  end

  def shops_by_user
    user = User.find_by(id: params[:user_id])
    shops = user ? user.shops.active.map { |s| { id: s.id, name: "#{s.name} (user:#{user.id})" } } : []
    render json: shops
  end

  def online_services_for_shop
    online_services = if params[:shop_id].present?
      shop = Shop.find_by(id: params[:shop_id])
      shop ? OnlineService.where(user_id: shop.user_id).not_deleted : OnlineService.none
    elsif params[:user_id].present?
      user = User.find_by(id: params[:user_id])
      user ? user.online_services.not_deleted : OnlineService.none
    else
      OnlineService.none
    end

    render json: online_services.map { |os| { id: os.id, name: os.name } }
  end

  def upload_image
    image = @event_content.event_content_images.create!(
      position: @event_content.event_content_images.count
    )
    image.image.attach(params[:image])
    render json: { id: image.id, url: image.image.attached? ? Rails.application.routes.url_helpers.rails_blob_url(image.image, only_path: true) : nil }
  end

  def destroy_image
    image = @event_content.event_content_images.find(params[:image_id])
    image.image.purge
    image.destroy!
    render json: { success: true }
  end

  private

  def set_event
    @event = Current.business_owner.events.undeleted.find(params[:event_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to lines_user_bot_events_path(business_owner_id: business_owner_id)
  end

  def set_event_content
    @event_content = EventContent.undeleted.joins(:event).where(events: { user_id: Current.business_owner.id }).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to lines_user_bot_events_path(business_owner_id: business_owner_id)
  end

  def require_team_plan!
    unless Current.business_owner.team_plan_member?
      redirect_to lines_user_bot_schedules_path(business_owner_id: business_owner_id)
    end
  end
end
