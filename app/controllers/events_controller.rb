# frozen_string_literal: true

class EventsController < ActionController::Base
  layout "booking"
  include ControllerHelpers
  include CompatReadFlags
  include CompatSession

  protect_from_forgery with: :exception, prepend: true

  prepend_before_action :set_event
  before_action :capture_event_referrers

  helper ApplicationHelper

  def show
    if @compat_event
      @current_event_line_user_id = session[:event_line_user_id].presence&.to_i
      render :show_compat
      return
    end

    @current_event_line_user = current_event_line_user
    @compat_public_read = compat_public_event_for_viewer?(@event.user_id)

    if @compat_public_read
      return
    end

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
    contents = @event.visible_event_contents_for(@current_event_line_user).order(Arel.sql("CASE content_type WHEN 0 THEN 0 ELSE 1 END"), :position)
    has_profile = @participant &&
                  ((@participant.concern_categories || []) - ["other"]).any?

    picked = []

    if has_profile
      roles = @participant.recommended_roles
      matched = contents.select { |c| ((c.exhibitor_roles || []) & roles).any? }
      picked = matched.first(3)
    end

    if picked.size < 3
      remaining = contents.to_a - picked
      picked += remaining.shuffle.first(3 - picked.size)
    end

    picked.map(&:id)
  end

  def set_event
    if compat_event_enabled?
      context = compat_fetch_v1_json(
        "/events/#{params[:slug]}/page_context",
        compat_event_context_query
      )&.dig("data")
      if context && compat_public_event_for_viewer?(context["owner_user_id"])
        @compat_event = context
        return
      end
    end

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
