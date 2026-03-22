# frozen_string_literal: true

class Events::ParticipationsController < Lines::CustomersController
  layout "booking"

  before_action :set_event

  def new
    @current_social_user = current_toruya_social_user
    redirect_to event_path(slug: @event.slug) unless @current_social_user

    @participant = @event.event_participants.find_by(social_user_id: @current_social_user.id)
    redirect_to event_path(slug: @event.slug) if @participant
  end

  def create
    @current_social_user = current_toruya_social_user
    return render json: { error: "LINEログインが必要です" }, status: :unauthorized unless @current_social_user

    outcome = Events::RegisterParticipant.run(
      event: @event,
      social_user: @current_social_user,
      business_types: params[:business_types],
      business_age: params[:business_age],
      concern_label: params[:concern_label],
      concern_other: params[:concern_other]
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

  def current_owner
    @event.user
  end
end
