# frozen_string_literal: true

class Lines::UserBot::EventsController < Lines::UserBotDashboardController
  before_action :require_team_plan!
  before_action :set_event, only: [:show, :edit, :update, :destroy, :analytics]

  def index
    @events = Current.business_owner.events.undeleted.order(created_at: :desc)
  end

  def new
    @event = Event.new
  end

  def create
    outcome = Events::Create.run(
      user: Current.business_owner,
      title: params[:title],
      slug: params[:slug],
      description: params[:description],
      start_at: params[:start_at],
      end_at: params[:end_at],
      published: params[:published]
    )

    return_json_response(outcome, { redirect_to: lines_user_bot_event_path(business_owner_id: business_owner_id, id: outcome.result&.id) })
  end

  def show
    @event_contents = @event.event_contents.undeleted.order(:position)
  end

  def edit
  end

  def update
    outcome = Events::Update.run(
      event: @event,
      title: params[:title],
      slug: params[:slug],
      description: params[:description],
      start_at: params[:start_at],
      end_at: params[:end_at],
      published: params[:published]
    )

    return_json_response(outcome, { redirect_to: lines_user_bot_event_path(business_owner_id: business_owner_id, id: @event.id) })
  end

  def destroy
    outcome = Events::Destroy.run(event: @event)

    if outcome.valid?
      redirect_to lines_user_bot_events_path(business_owner_id: business_owner_id), notice: I18n.t("common.delete_successfully_message")
    else
      redirect_to lines_user_bot_event_path(business_owner_id: business_owner_id, id: @event.id), alert: outcome.errors.full_messages.join(", ")
    end
  end

  def analytics
    @event_contents = @event.event_contents.undeleted.order(:position)
  end

  private

  def set_event
    @event = Current.business_owner.events.undeleted.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to lines_user_bot_events_path(business_owner_id: business_owner_id)
  end

  def require_team_plan!
    unless Current.business_owner.team_plan_member?
      redirect_to lines_user_bot_schedules_path(business_owner_id: business_owner_id)
    end
  end
end
