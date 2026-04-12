# frozen_string_literal: true

class Admin::EventContentsController < AdminController
  before_action :set_event, only: [:new, :create, :sort, :shops_by_user, :online_services_for_shop, :booking_pages_for_shop]
  before_action :set_event_content, only: [
    :show, :edit, :update, :destroy,
    :upload_image, :destroy_image, :sort_images,
    :add_speaker, :update_speaker, :destroy_speaker, :sort_speakers
  ]

  def new
    @event_content = @event.event_contents.new
  end

  def create
    @event_content = @event.event_contents.build(event_content_params)
    @event_content.position ||= @event.event_contents.maximum(:position).to_i + 1

    if params[:event_content][:thumbnail].present?
      @event_content.thumbnail.attach(params[:event_content][:thumbnail])
    end
    if params[:event_content][:exhibitor_logo].present?
      @event_content.exhibitor_logo.attach(params[:event_content][:exhibitor_logo])
    end

    if @event_content.save
      redirect_to admin_event_path(@event), notice: "コンテンツを作成しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @event = @event_content.event
  end

  def edit
    @event = @event_content.event
  end

  def update
    if params[:event_content][:thumbnail].present?
      @event_content.thumbnail.attach(params[:event_content][:thumbnail])
    end
    if params[:event_content][:exhibitor_logo].present?
      @event_content.exhibitor_logo.attach(params[:event_content][:exhibitor_logo])
    end

    if @event_content.update(event_content_params)
      redirect_to admin_event_path(@event_content.event), notice: "コンテンツを更新しました"
    else
      @event = @event_content.event
      render :edit, status: :unprocessable_entity
    end
  end

  def sort
    ids = params[:ids]
    return head :bad_request unless ids.is_a?(Array)

    ids.each_with_index do |id, index|
      EventContent.where(id: id).update_all(position: index)
    end

    head :ok
  end

  def destroy
    event = @event_content.event
    @event_content.soft_delete!
    redirect_to admin_event_path(event), notice: "コンテンツを削除しました"
  end

  # --- Slide images ---

  def upload_image
    image = @event_content.event_content_images.create!(
      position: @event_content.event_content_images.count
    )
    image.image.attach(params[:image])
    render json: {
      id: image.id,
      url: image.image.attached? ? Rails.application.routes.url_helpers.rails_blob_url(image.image, only_path: true) : nil
    }
  end

  def destroy_image
    image = @event_content.event_content_images.find(params[:image_id])
    image.image.purge
    image.destroy!
    render json: { success: true }
  end

  def sort_images
    ids = params[:ids]
    return head :bad_request unless ids.is_a?(Array)

    ids.each_with_index do |id, index|
      @event_content.event_content_images.where(id: id).update_all(position: index)
    end

    head :ok
  end

  # --- Speakers ---

  def add_speaker
    speaker = @event_content.event_content_speakers.build(
      name: params[:name],
      position_title: params[:position_title],
      introduction: params[:introduction],
      position: @event_content.event_content_speakers.maximum(:position).to_i + 1
    )
    speaker.profile_image.attach(params[:profile_image]) if params[:profile_image].present?
    speaker.save!

    render json: {
      id: speaker.id,
      name: speaker.name,
      position_title: speaker.position_title,
      introduction: speaker.introduction,
      profile_image_url: speaker.profile_image.attached? ? Rails.application.routes.url_helpers.rails_blob_url(speaker.profile_image, only_path: true) : nil
    }
  end

  def update_speaker
    speaker = @event_content.event_content_speakers.find(params[:speaker_id])
    speaker.update!(
      name: params[:name],
      position_title: params[:position_title],
      introduction: params[:introduction]
    )
    speaker.profile_image.attach(params[:profile_image]) if params[:profile_image].present?

    render json: {
      id: speaker.id,
      name: speaker.name,
      position_title: speaker.position_title,
      introduction: speaker.introduction,
      profile_image_url: speaker.profile_image.attached? ? Rails.application.routes.url_helpers.rails_blob_url(speaker.profile_image, only_path: true) : nil
    }
  end

  def destroy_speaker
    speaker = @event_content.event_content_speakers.find(params[:speaker_id])
    speaker.profile_image.purge if speaker.profile_image.attached?
    speaker.destroy!
    render json: { success: true }
  end

  def sort_speakers
    ids = params[:ids]
    return head :bad_request unless ids.is_a?(Array)

    ids.each_with_index do |id, index|
      @event_content.event_content_speakers.where(id: id).update_all(position: index)
    end

    head :ok
  end

  # --- Lookup APIs ---

  def shops_by_user
    user = User.find_by(id: params[:user_id])
    return render json: [] unless user

    shops = user.shops.map { |s| { id: s.id, name: s.name } }
    render json: shops
  end

  def online_services_for_shop
    shop = Shop.find_by(id: params[:shop_id])
    return render json: [] unless shop

    services = shop.user.online_services.map { |s| { id: s.id, title: s.name, slug: s.slug } }
    render json: services
  end

  def booking_pages_for_shop
    shop = Shop.find_by(id: params[:shop_id])
    return render json: [] unless shop

    pages = BookingPage.where(shop_id: shop.id).map { |p| { id: p.id, title: p.title || p.name, slug: p.slug } }
    render json: pages
  end

  private

  def set_event
    @event = Event.undeleted.find(params[:event_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_events_path, alert: "イベントが見つかりません"
  end

  def set_event_content
    @event_content = EventContent.undeleted.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_events_path, alert: "コンテンツが見つかりません"
  end

  def event_content_params
    permitted = params.require(:event_content).permit(
      :content_type, :title, :description, :introduction,
      :start_at, :end_at, :capacity, :position,
      :video_url, :pre_ad_video_url, :post_ad_video_url, :direct_download_url,
      :shop_id, :online_service_id,
      :upsell_booking_enabled, :upsell_booking_page_id,
      :monitor_enabled, :monitor_name, :monitor_price, :monitor_limit, :monitor_form_url,
      :exhibitor_company_name, :exhibitor_description, :exhibitor_logo,
      exhibitor_roles: []
    )
    permitted[:exhibitor_roles] = (permitted[:exhibitor_roles] || []).reject(&:blank?)
    permitted
  end
end
