# frozen_string_literal: true

class EventsController < ActionController::Base
  layout "booking"
  include ControllerHelpers

  protect_from_forgery with: :exception, prepend: true

  prepend_before_action :set_event

  helper ApplicationHelper

  def show
    @current_event_line_user = current_event_line_user
    @participant = @current_event_line_user ? @event.event_participants.find_by(event_line_user_id: @current_event_line_user.id) : nil

    @event_hash = EventSerializer.new(@event, {
      params: {
        event_line_user: @current_event_line_user,
        participant: @participant
      }
    }).attributes_hash
  end

  private

  def set_event
    @event = Event.published.undeleted.find_by!(slug: params[:slug])
  rescue ActiveRecord::RecordNotFound
    render plain: "イベントが見つかりません", status: :not_found
  end

  def current_event_line_user
    return @_current_event_line_user if defined?(@_current_event_line_user)

    @_current_event_line_user = session[:event_line_user_id] ? EventLineUser.find_by(id: session[:event_line_user_id]) : nil
  end
  helper_method :current_event_line_user
end
