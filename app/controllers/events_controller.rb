# frozen_string_literal: true

class EventsController < Lines::CustomersController
  layout "booking"

  prepend_before_action :set_event

  def show
    @current_social_customer = current_social_customer
    @participant = @event.event_participants.find_by(social_customer_id: @current_social_customer&.id)

    @event_hash = EventSerializer.new(@event, {
      params: {
        social_customer: @current_social_customer,
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

  def current_owner
    @event.user
  end
end
