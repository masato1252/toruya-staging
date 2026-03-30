# frozen_string_literal: true

class Admin::EventContentsController < AdminController
  before_action :set_event, only: [:new, :create]
  before_action :set_event_content, only: [:show, :edit, :update, :destroy, :upload_image, :destroy_image]

  def new
    @event_content = @event.event_contents.new
  end

  def create
    @event_content = @event.event_contents.build(event_content_params)

    if params[:event_content][:thumbnail].present?
      @event_content.thumbnail.attach(params[:event_content][:thumbnail])
    end

    if @event_content.save
      redirect_to admin_event_content_path(@event_content), notice: "コンテンツを作成しました"
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

    if @event_content.update(event_content_params)
      redirect_to admin_event_content_path(@event_content), notice: "コンテンツを更新しました"
    else
      @event = @event_content.event
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    event = @event_content.event
    @event_content.soft_delete!
    redirect_to admin_event_path(event), notice: "コンテンツを削除しました"
  end

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
    params.require(:event_content).permit(
      :content_type, :title, :description, :introduction,
      :start_at, :end_at, :capacity, :position,
      :pre_ad_video_url, :post_ad_video_url, :direct_download_url,
      :upsell_booking_enabled, :monitor_enabled,
      :monitor_name, :monitor_price, :monitor_limit, :monitor_form_url
    )
  end
end
