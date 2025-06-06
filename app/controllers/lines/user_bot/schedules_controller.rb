# frozen_string_literal: true

class Lines::UserBot::SchedulesController < Lines::UserBotDashboardController
  include SchedulesHelper

  def mine
    working_shop_ids = current_social_user.shops.map(&:id).uniq
    get_date(working_shop_ids)

    schedules = Schedules::Events.run!(
      working_shop_ids: working_shop_ids,
      user_ids: current_social_user.current_users.pluck(:id),
      date: @date,
      month_date: @month_date
    )

    schedules[:reservations] = schedules[:reservations].find_all do |r|
      user_ability = ability(r.shop.user, r.shop)
      user_ability.responsible_for_reservation(r)
    end
    @schedules = schedules_events(schedules)
    @reservation = schedules[:reservations].find { |r| r.id.to_s == params[:reservation_id] } if params[:reservation_id]

    notification_presenter = NotificationsPresenter.new(view_context, Current.user, params.merge(my_calendar: true))
    @notification_messages = notification_presenter.data
    @reservations_approval_flow = notification_presenter.reservations_approval_flow

    @my_calendar = true
    @schedules_for_calendar = @schedules
    @schedule_mode = Current.business_owner.schedule_mode

    if @schedule_mode == "calendar"
      render action: :calendar
    else
      render action: :index
    end
  end

  def index
    working_shop_ids = Current.business_owner.shop_ids
    get_date(working_shop_ids)

    schedules = Schedules::Events.run!(
      working_shop_ids: working_shop_ids,
      user_ids: Current.business_owner.all_staff_related_users.pluck(:id),
      date: @date,
      month_date: @month_date
    )

    @schedules = schedules_events(schedules)
    @related_user_ids = Current.business_owner.related_users.map(&:id)
    @reservation = schedules[:reservations].find { |r| r.id.to_s == params[:reservation_id] } if params[:reservation_id]
    notification_presenter = NotificationsPresenter.new(view_context, Current.business_owner, params)
    @notification_messages = notification_presenter.data
    @reservations_approval_flow = notification_presenter.reservations_approval_flow

    @schedules_for_calendar = @schedules

    if Current.business_owner.schedule_mode == "calendar"
      render action: :calendar
    else
      render action: :index
    end
  end

  def events
    working_shop_ids = Current.business_owner.shop_ids
    get_date(working_shop_ids)

    schedules = Schedules::Events.run!(
      working_shop_ids: working_shop_ids,
      user_ids: Current.business_owner.all_staff_related_users.pluck(:id),
      period_start_date: Date.parse(params[:schedule_start_date]),
      period_end_date: Date.parse(params[:schedule_end_date])
    )

    events = schedules_events(schedules)
    render json: events
  end

  def toggle_mode
    current_mode = Current.business_owner.schedule_mode
    new_mode = current_mode == "calendar" ? "list" : "calendar"

    Current.business_owner.user_setting.update!(schedule_mode: new_mode)

    head :ok
  end

  private

  def get_date(working_shop_ids)
    @date =
      if Current.business_owner.schedule_mode == "calendar"
        @month_date = if params[:reservation_date].present? || params[:month_date].present?
                        Time.zone.parse(params[:reservation_date] || params[:month_date]).to_date
                      else
                        Time.zone.now.to_date
                      end
        Time.zone.now.to_date
      else
        if params[:reservation_date].present?
          Time.zone.parse(params[:reservation_date]).to_date
        elsif params[:reservation_id].present?
          Reservation.where(shop_id: working_shop_ids).find(params[:reservation_id]).start_time.to_date
        else
          @month_date = if params[:month_date].present?
                          Time.zone.parse(params[:month_date]).to_date
                        end

          Time.zone.now.to_date
        end
      end
  end
end
