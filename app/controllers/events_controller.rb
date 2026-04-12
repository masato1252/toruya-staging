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
        participant: @participant,
        recommended_content_ids: compute_recommended_content_ids
      }
    }).attributes_hash
  end

  private

  def compute_recommended_content_ids
    contents = @event.event_contents.undeleted.order(Arel.sql("CASE content_type WHEN 0 THEN 0 ELSE 1 END"), :position)
    has_profile = @participant &&
                  ((@participant.concern_categories || []) - ["other"]).any?

    if has_profile
      roles = @participant.recommended_roles
      matched = contents.select { |c| ((c.exhibitor_roles || []) & roles).any? }
      return matched.first(3).map(&:id) if matched.any?
    end

    contents.to_a.shuffle.first(3).map(&:id)
  end

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
