# frozen_string_literal: true

require "ostruct"

class Lines::UserBot::SchedulesController < Lines::UserBotDashboardController
  include SchedulesHelper

  def mine
    if compat_read_data_plane?
      render_compat_schedules(mine: true)
      return
    end

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

    if compat_read_enabled?
      @notification_messages = []
      @reservations_approval_flow = []
    else
      notification_presenter = NotificationsPresenter.new(view_context, Current.user, params.merge(my_calendar: true))
      @notification_messages = notification_presenter.data
      @reservations_approval_flow = notification_presenter.reservations_approval_flow
    end

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
    if compat_read_data_plane?
      render_compat_schedules(mine: false)
      return
    end

    working_shop_ids = Current.business_owner.shop_ids
    get_date(working_shop_ids)

    schedules = Schedules::Events.run!(
      working_shop_ids: working_shop_ids,
      user_ids: Current.business_owner.all_staff_related_users.pluck(:id),
      visible_open_schedule_user_ids: current_social_user.current_users.pluck(:id),
      date: @date,
      month_date: @month_date
    )

    @schedules = schedules_events(schedules)
    @related_user_ids = Current.business_owner.related_users.map(&:id)
    @reservation = schedules[:reservations].find { |r| r.id.to_s == params[:reservation_id] } if params[:reservation_id]
    if compat_read_enabled?
      @notification_messages = []
      @reservations_approval_flow = []
    else
      notification_presenter = NotificationsPresenter.new(view_context, Current.business_owner, params)
      @notification_messages = notification_presenter.data
      @reservations_approval_flow = notification_presenter.reservations_approval_flow
    end

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
      visible_open_schedule_user_ids: current_social_user.current_users.pluck(:id),
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

  def render_compat_schedules(mine:)
    @related_user_ids = []
    @notification_messages = []
    @reservations_approval_flow = []
    @my_calendar = mine
    @schedule_mode = compat_schedule_mode
    owner_id = resolve_compat_owner_id(nil) || resolve_compat_id(current_user&.id) || Current.business_owner&.id

    if @schedule_mode == "calendar"
      @month_date =
        if params[:reservation_date].present? || params[:month_date].present?
          Time.zone.parse(params[:reservation_date] || params[:month_date]).to_date
        else
          Time.zone.now.to_date
        end
      @date = Time.zone.now.to_date
      range_start = @month_date.beginning_of_month
      range_end = @month_date.end_of_month
    else
      compat_get_date
      if @month_date
        range_start = @month_date.beginning_of_month
        range_end = @month_date.end_of_month
      else
        range_start = @date
        range_end = @date
      end
    end

    @schedules = compat_fetch_schedule_events(
      owner_id: owner_id,
      start_date: range_start,
      end_date: range_end,
      mine: mine
    )
    @schedules_for_calendar = @schedules
    @reservation = @schedules.find { |s| s[:type] == :reservation && s[:id].to_s == params[:reservation_id].to_s } if params[:reservation_id]
    @compat_shops = compat_fetch_shops(owner_id)

    if @schedule_mode == "calendar"
      render :calendar
    else
      # Reuse legacy index + _events for full UI/UX parity (modals, date headers, row layout).
      render :index
    end
  end

  def compat_fetch_schedule_events(owner_id:, start_date:, end_date:, mine:)
    return [] if owner_id.blank?

    query = {
      schedule_start_date: start_date.to_s,
      schedule_end_date: end_date.to_s,
      current_user_id: current_user&.id,
      visible_open_schedule_user_ids: current_user&.id,
    }
    query[:my_calendar] = true if mine

    body = fetch_v1_json(
      "/lines/user_bot/owner/#{owner_id}/schedules/events",
      query.compact
    )
    events = body.is_a?(Array) ? body : Array(body)
    events.map { |event| normalize_compat_schedule_event(event) }.compact
  rescue StandardError => e
    Rails.logger.warn("[SchedulesController] compat events failed: #{e.message}")
    []
  end

  def normalize_compat_schedule_event(raw)
    return nil unless raw.is_a?(Hash)

    event = raw.deep_symbolize_keys
    event[:type] = event[:type].to_s.to_sym if event[:type]
    event[:shop] ||= event[:shop_id]
    if event[:time].is_a?(String)
      event[:time] = Time.zone.parse(event[:time]) rescue event[:time]
    end
    if event[:sentences].is_a?(Array)
      event[:sentences] = { deleted_staffs_sentence: nil }
    elsif event[:sentences].is_a?(Hash)
      event[:sentences] = event[:sentences].deep_symbolize_keys
    end
    event
  end

  def compat_fetch_shops(owner_id)
    return [] if owner_id.blank?

    body = compat_fetch_v1_json("/lines/user_bot/owner/#{owner_id}/settings/shops")
    items = body&.dig("data") || body&.dig("items") || []
    Array(items).map do |shop|
      row = shop.is_a?(Hash) ? shop.deep_symbolize_keys : {}
      OpenStruct.new(
        id: row[:id],
        name: row[:name] || row[:short_name],
        display_name: row[:short_name].presence || row[:name],
        user_id: owner_id
      )
    end
  rescue StandardError => e
    Rails.logger.warn("[SchedulesController] compat shops failed: #{e.message}")
    []
  end

  # Always read schedule_mode from Supabase-backed auth/session — never Heroku AR.
  def compat_schedule_mode
    if Current.business_owner.is_a?(CompatBusinessOwner)
      return Current.business_owner.schedule_mode
    end

    payload = @compat_session_payload
    payload ||= compat_auth_session(
      owner_id: Current.business_owner&.id || resolve_compat_owner_id(nil),
      current_user_id: current_user&.id
    )
    payload&.dig("schedule_mode") == "calendar" ? "calendar" : "list"
  end

  def compat_get_date
    @date =
      if params[:reservation_date].present?
        Time.zone.parse(params[:reservation_date]).to_date
      else
        Time.zone.now.to_date
      end
    @month_date = params[:month_date].present? ? Time.zone.parse(params[:month_date]).to_date : nil
  end

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
