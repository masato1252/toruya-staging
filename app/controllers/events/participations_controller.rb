# frozen_string_literal: true

class Events::ParticipationsController < Lines::CustomersController
  layout "booking"

  prepend_before_action :set_event

  def new
    @current_social_customer = current_social_customer
    redirect_to event_path(slug: @event.slug) and return unless @current_social_customer

    @participant = @event.event_participants.find_by(social_customer_id: @current_social_customer.id)
    redirect_to event_path(slug: @event.slug) and return if @participant
  end

  def create
    @current_social_customer = current_social_customer
    return render json: { error: "LINEログインが必要です" }, status: :unauthorized unless @current_social_customer

    outcome = Events::RegisterParticipant.run(
      event: @event,
      social_customer: @current_social_customer,
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
