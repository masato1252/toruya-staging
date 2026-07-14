# frozen_string_literal: true

class Events::ParticipationsController < ActionController::Base
  layout "booking"
  include ControllerHelpers
  include CompatSession

  protect_from_forgery with: :exception, prepend: true

  prepend_before_action :set_event
  before_action :capture_event_referrers, only: [:new]

  helper ApplicationHelper

  def new
    @current_event_line_user = current_event_line_user
    redirect_to event_path(slug: @event.slug) and return unless @current_event_line_user

    @participant = @event.event_participants.find_by(event_line_user_id: @current_event_line_user.id)
    if @participant && @current_event_line_user.basic_profile_complete?
      redirect_to event_path(slug: @event.slug) and return
    end

    @profile_completion_mode = @participant.present?

    profile = @current_event_line_user.toruya_user&.profile
    @initial_first_name = @current_event_line_user.first_name.presence || profile&.first_name
    @initial_last_name = @current_event_line_user.last_name.presence || profile&.last_name
    @initial_phone_number = @current_event_line_user.phone_number.presence || profile&.phone_number
    @initial_email = @current_event_line_user.email.presence || @current_event_line_user.toruya_user&.email.presence || profile&.email
  end

  def create
    if compat_public_event_create?
      event_line_user_id = session[:event_line_user_id]
      return render json: { error: "LINEログインが必要です" }, status: :unauthorized unless event_line_user_id

      ref = cookies.encrypted["event_ref_#{params[:event_slug]}"]
      ref = ref.is_a?(Hash) ? ref : {}
      result = compat_v1_post(
        "/events/#{params[:event_slug]}/participation",
        {
          event_line_user_id: event_line_user_id,
          business_types: params[:business_types],
          business_age: params[:business_age],
          concern_labels: params[:concern_labels],
          concern_other: params[:concern_other],
          first_name: params[:first_name],
          last_name: params[:last_name],
          phone_number: params[:phone_number],
          email: params[:email],
          referrer_shop_id: ref["rs"],
          referrer_event_line_user_id: ref["ru"]
        }
      )
      if result&.dig("status") == "successful"
        render json: result["data"] || { success: true, redirect_to: event_path(slug: params[:event_slug]) }
      else
        render json: {
          error_message: result&.dig("error_message") || "参加登録に失敗しました"
        }, status: :unprocessable_entity
      end
      return
    end

    @current_event_line_user = current_event_line_user
    return render json: { error: "LINEログインが必要です" }, status: :unauthorized unless @current_event_line_user

    ref = cookies.encrypted["event_ref_#{@event.slug}"]
    ref = ref.is_a?(Hash) ? ref : {}

    outcome = Events::RegisterParticipant.run(
      event: @event,
      event_line_user: @current_event_line_user,
      business_types: params[:business_types],
      business_age: params[:business_age],
      concern_labels: params[:concern_labels],
      concern_other: params[:concern_other],
      first_name: params[:first_name],
      last_name: params[:last_name],
      phone_number: params[:phone_number],
      email: params[:email],
      referrer_shop_id: ref["rs"],
      referrer_event_line_user_id: ref["ru"],
      referrer_event_content_id: ref["rc"]
    )

    if outcome.valid?
      render json: { success: true, redirect_to: event_path(slug: @event.slug) }
    else
      render json: { error_message: outcome.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end
  end

  private

  def set_event
    return if compat_public_event_create?

    @event = Event.published.undeleted.find_by!(slug: params[:event_slug])
  rescue ActiveRecord::RecordNotFound
    render plain: "イベントが見つかりません", status: :not_found
  end

  def current_event_line_user
    return @_current_event_line_user if defined?(@_current_event_line_user)

    @_current_event_line_user = session[:event_line_user_id] ? EventLineUser.find_by(id: session[:event_line_user_id]) : nil
  end

  def compat_public_event_create?
    return false unless action_name == "create"
    return @_compat_public_event_create if defined?(@_compat_public_event_create)

    context = compat_fetch_v1_json("/events/#{params[:event_slug]}/page_context")&.dig("data")
    @_compat_public_event_create = context.present? &&
      compat_public_read_for_owner?(context["owner_user_id"])
  end

  helper_method :current_event_line_user
end
