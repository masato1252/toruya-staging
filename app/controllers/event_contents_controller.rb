# frozen_string_literal: true

class EventContentsController < Lines::CustomersController
  layout "booking"

  before_action :set_event
  before_action :set_event_content

  def show
    @current_social_user = current_toruya_social_user
    @participant = @event.event_participants.find_by(social_user_id: @current_social_user&.id)
    @usage = @event_content.event_content_usages.find_by(social_user_id: @current_social_user&.id)
    @consultation = @event_content.event_upsell_consultations.find_by(social_user_id: @current_social_user&.id)
    @monitor_application = @event_content.event_monitor_applications.find_by(social_user_id: @current_social_user&.id)

    if @current_social_user
      ahoy.track("event_content_view", {
        event_content_id: @event_content.id.to_s,
        social_user_id: @current_social_user.social_service_user_id
      })
    end

    @event_content_hash = EventContentSerializer.new(@event_content, {
      params: {
        social_user: @current_social_user,
        participant: @participant,
        usage: @usage,
        consultation: @consultation,
        monitor_application: @monitor_application
      }
    }).attributes_hash
  end

  def start_usage
    @current_social_user = current_toruya_social_user
    return render json: { error: "参加登録が必要です" }, status: :unauthorized unless @current_social_user
    return render json: { error: "参加登録が必要です" }, status: :unauthorized unless @event.event_participants.exists?(social_user_id: @current_social_user.id)

    if @event_content.capacity_full?
      render json: { error: "利用開始の上限に達しました" }, status: :unprocessable_entity
      return
    end

    usage = @event_content.event_content_usages.find_or_initialize_by(social_user_id: @current_social_user.id)
    if usage.new_record?
      usage.started_at = Time.current
      usage.save!
    end

    render json: { success: true }
  end

  def upsell_consultation
    @current_social_user = current_toruya_social_user
    return render json: { error: "参加登録が必要です" }, status: :unauthorized unless @current_social_user

    consultation = @event_content.event_upsell_consultations.find_or_initialize_by(social_user_id: @current_social_user.id)
    if consultation.new_record?
      consultation.status = :waitlist
      consultation.save!
      Events::NotifyWaitlist.run(consultation: consultation)
    end

    render json: { success: true, status: consultation.status }
  end

  def monitor_apply
    @current_social_user = current_toruya_social_user
    return render json: { error: "参加登録が必要です" }, status: :unauthorized unless @current_social_user

    application = @event_content.event_monitor_applications.find_or_initialize_by(social_user_id: @current_social_user.id)
    if application.new_record?
      application.save!
      Events::NotifyMonitorApplication.run(application: application)
    end

    form_url = build_monitor_form_url(@event_content, @current_social_user)
    render json: { success: true, form_url: form_url }
  end

  private

  def set_event
    @event = Event.published.undeleted.find_by!(slug: params[:event_slug])
  rescue ActiveRecord::RecordNotFound
    render plain: "イベントが見つかりません", status: :not_found
  end

  def set_event_content
    @event_content = @event.event_contents.undeleted.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render plain: "コンテンツが見つかりません", status: :not_found
  end

  def current_owner
    @event.user
  end

  def build_monitor_form_url(event_content, social_user)
    return nil unless event_content.monitor_form_url.present?

    uri = URI.parse(event_content.monitor_form_url)
    query_params = URI.decode_www_form(uri.query || "")
    query_params << ["entry.social_id", social_user.social_service_user_id]
    query_params << ["entry.user_id", social_user.users.first&.id.to_s]
    uri.query = URI.encode_www_form(query_params)
    uri.to_s
  rescue URI::InvalidURIError
    event_content.monitor_form_url
  end
end
