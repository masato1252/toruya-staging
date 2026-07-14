# frozen_string_literal: true

class Admin::EventContentsController < AdminController
  before_action :set_event, only: [:new, :create, :sort, :shops_by_user, :online_services_for_shop, :booking_pages_for_shop, :shop_acquisition_counts]
  before_action :set_event_content, only: [
    :show, :edit, :update, :destroy,
    :upload_image, :destroy_image, :sort_images,
    :add_speaker, :update_speaker, :destroy_speaker, :sort_speakers
  ]

  def new
    if compat_read_data_plane?
      @compat_event_content_context = compat_fetch_v1_json(
        "/admin/events/#{params[:event_id]}/event_contents/page_context"
      )&.dig("data")
      unless @compat_event_content_context
        redirect_to admin_events_path, alert: "イベントが見つかりません"
        return
      end
      render :new_compat
      return
    end

    @event_content = @event.event_contents.new
  end

  def create
    if compat_read_data_plane?
      response = compat_event_content_request(
        Net::HTTP::Post,
        "/admin/events/#{params[:event_id]}/event_contents"
      )
      render_compat_event_content_response(response)
      return
    end

    @event_content = @event.event_contents.build(event_content_params)
    # position はカラムデフォルトが 0 (not null) のため ||= では採番されない。
    # 新規作成時は常に末尾に追加する（既存コンテンツの position は触らない）。
    if @event_content.position.nil? || @event_content.position.zero?
      @event_content.position = @event.event_contents.undeleted.maximum(:position).to_i + 1
    end

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
    if compat_admin_enabled?
      @compat_event_content = compat_fetch_v1_json(
        "/admin/event_contents/#{params[:id]}/page_context"
      )&.dig("data")
      unless @compat_event_content
        redirect_to admin_events_path, alert: "コンテンツが見つかりません"
        return
      end
      render :show_compat
      return
    end

    @event = @event_content.event
  end

  def edit
    if compat_read_data_plane?
      @compat_event_content_context = compat_fetch_v1_json(
        "/admin/event_contents/#{params[:id]}/page_context"
      )&.dig("data")
      unless @compat_event_content_context
        redirect_to admin_events_path, alert: "コンテンツが見つかりません"
        return
      end
      render :edit_compat
      return
    end

    @event = @event_content.event
  end

  def update
    if compat_read_data_plane?
      response = compat_event_content_request(
        Net::HTTP::Put,
        "/admin/event_contents/#{params[:id]}"
      )
      render_compat_event_content_response(response)
      return
    end

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
    if compat_read_data_plane?
      response = compat_v1_json_response(
        Net::HTTP::Put,
        "/admin/events/#{params[:event_id]}/event_contents/sort",
        ids: params[:ids]
      )
      response&.dig(:success) ? head(:ok) : head(:unprocessable_entity)
      return
    end

    ids = params[:ids]
    return head :bad_request unless ids.is_a?(Array)

    ids.each_with_index do |id, index|
      EventContent.where(id: id).update_all(position: index)
    end

    head :ok
  end

  def destroy
    if compat_read_data_plane?
      response = compat_v1_json_response(
        Net::HTTP::Delete,
        "/admin/event_contents/#{params[:id]}"
      )
      if response&.dig(:success)
        redirect_to response.dig(:body, "redirect_to") || admin_events_path,
                    notice: "コンテンツを削除しました"
      else
        redirect_to admin_events_path, alert: "コンテンツを削除できませんでした"
      end
      return
    end

    event = @event_content.event
    @event_content.soft_delete!
    redirect_to admin_event_path(event), notice: "コンテンツを削除しました"
  end

  # --- Slide images ---

  def upload_image
    if compat_read_data_plane?
      response = compat_v1_multipart_response(
        Net::HTTP::Post,
        "/admin/event_contents/#{params[:id]}/images",
        {},
        image: params[:image]
      )
      render json: response&.dig(:body) || { status: "failed", error_message: "画像を保存できませんでした" },
             status: response&.dig(:status) || :bad_gateway
      return
    end

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
    if compat_read_data_plane?
      response = compat_v1_delete(
        "/admin/event_contents/#{params[:id]}/images/#{params[:image_id]}"
      )
      render json: response || { status: "failed" },
             status: response&.dig("status") == "successful" ? :ok : :unprocessable_entity
      return
    end

    image = @event_content.event_content_images.find(params[:image_id])
    image.image.purge
    image.destroy!
    render json: { success: true }
  end

  def sort_images
    if compat_read_data_plane?
      response = compat_v1_put(
        "/admin/event_contents/#{params[:id]}/sort_images",
        ids: params[:ids]
      )
      response&.dig("status") == "successful" ? head(:ok) : head(:unprocessable_entity)
      return
    end

    ids = params[:ids]
    return head :bad_request unless ids.is_a?(Array)

    ids.each_with_index do |id, index|
      @event_content.event_content_images.where(id: id).update_all(position: index)
    end

    head :ok
  end

  # --- Speakers ---

  def add_speaker
    if compat_read_data_plane?
      response = compat_speaker_request(
        Net::HTTP::Post,
        "/admin/event_contents/#{params[:id]}/speakers"
      )
      render json: response&.dig(:body) || { status: "failed", error_message: "登壇者を保存できませんでした" },
             status: response&.dig(:status) || :bad_gateway
      return
    end

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
    if compat_read_data_plane?
      response = compat_speaker_request(
        Net::HTTP::Put,
        "/admin/event_contents/#{params[:id]}/speakers/#{params[:speaker_id]}"
      )
      render json: response&.dig(:body) || { status: "failed", error_message: "登壇者を保存できませんでした" },
             status: response&.dig(:status) || :bad_gateway
      return
    end

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
    if compat_read_data_plane?
      response = compat_v1_delete(
        "/admin/event_contents/#{params[:id]}/speakers/#{params[:speaker_id]}"
      )
      render json: response || { status: "failed" },
             status: response&.dig("status") == "successful" ? :ok : :unprocessable_entity
      return
    end

    speaker = @event_content.event_content_speakers.find(params[:speaker_id])
    speaker.profile_image.purge if speaker.profile_image.attached?
    speaker.destroy!
    render json: { success: true }
  end

  def sort_speakers
    if compat_read_data_plane?
      response = compat_v1_put(
        "/admin/event_contents/#{params[:id]}/sort_speakers",
        ids: params[:ids]
      )
      response&.dig("status") == "successful" ? head(:ok) : head(:unprocessable_entity)
      return
    end

    ids = params[:ids]
    return head :bad_request unless ids.is_a?(Array)

    ids.each_with_index do |id, index|
      @event_content.event_content_speakers.where(id: id).update_all(position: index)
    end

    head :ok
  end

  # --- Lookup APIs ---

  def shops_by_user
    if compat_read_data_plane?
      rows = compat_fetch_v1_json(
        "/admin/events/#{params[:event_id]}/event_contents/shops_by_user",
        user_id: params[:user_id]
      )
      render json: rows || []
      return
    end

    user = User.find_by(id: params[:user_id])
    return render json: [] unless user

    shops = user.shops.map { |s| { id: s.id, name: s.name } }
    render json: shops
  end

  def online_services_for_shop
    if compat_read_data_plane?
      rows = compat_fetch_v1_json(
        "/admin/events/#{params[:event_id]}/event_contents/online_services_for_shop",
        shop_id: params[:shop_id]
      )
      render json: rows || []
      return
    end

    shop = Shop.find_by(id: params[:shop_id])
    return render json: [] unless shop

    services = shop.user.online_services.map { |s| { id: s.id, title: s.name, slug: s.slug } }
    render json: services
  end

  def booking_pages_for_shop
    if compat_read_data_plane?
      rows = compat_fetch_v1_json(
        "/admin/events/#{params[:event_id]}/event_contents/booking_pages_for_shop",
        shop_id: params[:shop_id]
      )
      render json: rows || []
      return
    end

    shop = Shop.find_by(id: params[:shop_id])
    return render json: [] unless shop

    pages = BookingPage.where(shop_id: shop.id).map { |p| { id: p.id, title: p.title || p.name, slug: p.slug } }
    render json: pages
  end

  # 紐付け先 shop の、このイベントにおける集客数 (直接 + 間接) を返す。
  def shop_acquisition_counts
    if compat_read_data_plane?
      counts = compat_fetch_v1_json(
        "/admin/events/#{params[:event_id]}/event_contents/shop_acquisition_counts",
        shop_id: params[:shop_id]
      )
      render json: counts || { direct: 0, indirect: 0, total: 0 }
      return
    end

    shop_id = params[:shop_id]
    return render json: { direct: 0, indirect: 0, total: 0 } if shop_id.blank?

    counts = @event.shop_acquisition_counts(shop_id)
    render json: counts
  end

  private

  def set_event
    return if compat_read_data_plane? && %w[
      new create sort shops_by_user online_services_for_shop booking_pages_for_shop
      shop_acquisition_counts
    ].include?(action_name)

    @event = Event.undeleted.find(params[:event_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_events_path, alert: "イベントが見つかりません"
  end

  def set_event_content
    return if compat_read_data_plane? && %w[
      show edit update destroy upload_image destroy_image sort_images
      add_speaker update_speaker destroy_speaker sort_speakers
    ].include?(action_name)

    @event_content = EventContent.undeleted.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_events_path, alert: "コンテンツが見つかりません"
  end

  def event_content_params
    # position は並び替え専用の sort アクションで管理する。
    # create/update ではユーザー入力を受け付けず、誤って並び順が変わらないようにする。
    permitted = params.require(:event_content).permit(
      :status,
      :content_type, :title, :description, :introduction,
      :start_at, :end_at, :capacity,
      :video_url, :pre_ad_video_url, :post_ad_video_url, :direct_download_url,
      :shop_id, :online_service_id,
      :upsell_booking_enabled, :upsell_booking_page_id,
      :monitor_enabled, :monitor_name, :monitor_price, :monitor_limit, :monitor_form_url,
      :exhibitor_company_name, :exhibitor_description, :exhibitor_logo,
      exhibitor_roles: [],
      related_content_ids: [],
      related_documents: [:id, :title, :url]
    )
    permitted[:exhibitor_roles] = (permitted[:exhibitor_roles] || []).reject(&:blank?)
    permitted[:related_content_ids] = (permitted[:related_content_ids] || []).reject(&:blank?)
    permitted[:related_documents] = (permitted[:related_documents] || []).map do |doc|
      doc.respond_to?(:permit) ? doc.permit(:id, :title, :url).to_h : doc
    end
    permitted
  end

  def compat_event_content_request(request_class, path)
    permitted = event_content_params
    thumbnail = params.dig(:event_content, :thumbnail)
    exhibitor_logo = permitted.delete(:exhibitor_logo)
    payload = permitted.to_h
    payload.each do |key, value|
      payload[key] = value.to_json if value.is_a?(Array) || value.is_a?(Hash)
    end
    files = { thumbnail: thumbnail, exhibitor_logo: exhibitor_logo }
    if files.values.any?(&:present?)
      compat_v1_multipart_response(request_class, path, payload, files)
    else
      compat_v1_json_response(request_class, path, payload)
    end
  end

  def render_compat_event_content_response(response)
    if response&.dig(:success) && response.dig(:body, "status") == "successful"
      redirect_to response.dig(:body, "redirect_to") || admin_events_path,
                  notice: "コンテンツを保存しました"
    else
      redirect_back fallback_location: admin_events_path,
                    alert: response&.dig(:body, "error_message") || "コンテンツを保存できませんでした"
    end
  end

  def compat_speaker_request(request_class, path)
    compat_v1_multipart_response(
      request_class,
      path,
      {
        name: params[:name],
        position_title: params[:position_title],
        introduction: params[:introduction]
      },
      profile_image: params[:profile_image]
    )
  end
end
