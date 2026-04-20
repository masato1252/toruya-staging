# frozen_string_literal: true

class Events::ParticipationsController < ActionController::Base
  layout "booking"
  include ControllerHelpers

  protect_from_forgery with: :exception, prepend: true

  prepend_before_action :set_event
  before_action :capture_event_referrers, only: [:new]

  helper ApplicationHelper

  def new
    @current_event_line_user = current_event_line_user
    redirect_to event_path(slug: @event.slug) and return unless @current_event_line_user

    @participant = @event.event_participants.find_by(event_line_user_id: @current_event_line_user.id)
    redirect_to event_path(slug: @event.slug) and return if @participant

    profile = @current_event_line_user.toruya_user&.profile
    @initial_first_name = @current_event_line_user.first_name.presence || profile&.first_name
    @initial_last_name = @current_event_line_user.last_name.presence || profile&.last_name
    @initial_phone_number = @current_event_line_user.phone_number.presence || profile&.phone_number
    @initial_email = @current_event_line_user.email.presence || @current_event_line_user.toruya_user&.email.presence || profile&.email
  end

  def create
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
      referrer_event_line_user_id: ref["ru"]
    )

    if outcome.valid?
      render json: { success: true, redirect_to: event_path(slug: @event.slug) }
    else
      render json: { error_message: outcome.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end
  end

  private

  def set_event
    @event = Event.published.undeleted.find_by!(slug: params[:event_slug])
  rescue ActiveRecord::RecordNotFound
    render plain: "イベントが見つかりません", status: :not_found
  end

  def current_event_line_user
    return @_current_event_line_user if defined?(@_current_event_line_user)

    @_current_event_line_user = session[:event_line_user_id] ? EventLineUser.find_by(id: session[:event_line_user_id]) : nil
  end
  helper_method :current_event_line_user
end
