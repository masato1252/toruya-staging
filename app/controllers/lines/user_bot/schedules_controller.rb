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
    if compat_read_data_plane?
      owner_id = resolve_compat_owner_id(nil) || resolve_compat_current_user_id(nil)
      payload = owner_id && compat_fetch_v1_json(
        "/lines/user_bot/owner/#{owner_id}/schedules/events",
        {
          schedule_start_date: params[:schedule_start_date],
          schedule_end_date: params[:schedule_end_date],
          current_user_id: resolve_compat_current_user_id(nil)
        }
      )
      render json: payload || [], status: payload ? :ok : :bad_gateway
      return
    end

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
    if compat_read_data_plane?
      owner_id = resolve_compat_owner_id(nil) || resolve_compat_current_user_id(nil)
      result = owner_id && compat_v1_post(
        "/lines/user_bot/owner/#{owner_id}/schedules/toggle_mode"
      )
      head(result ? :ok : :bad_gateway)
      return
    end

    current_mode = Current.business_owner.schedule_mode
    new_mode = current_mode == "calendar" ? "list" : "calendar"

    Current.business_owner.user_setting.update!(schedule_mode: new_mode)

    head :ok
  end

  private

  def render_compat_schedules(mine:)
    @related_user_ids = []
    @my_calendar = mine
    @schedule_mode = compat_schedule_mode
    owner_id = resolve_compat_owner_id(nil) || resolve_compat_id(current_user&.id) || Current.business_owner&.id
    compat_assign_notification_banners(owner_id)

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

  def compat_assign_notification_banners(owner_id)
    @notification_messages = []
    @reservations_approval_flow = false
    return if owner_id.blank?

    payload = fetch_v1_json(
      "/lines/user_bot/owner/#{owner_id}/notifications",
      { current_user_id: current_user&.id }.compact
    )
    data = payload.is_a?(Hash) ? (payload["data"] || payload[:data] || payload) : {}
    data = data.deep_stringify_keys if data.respond_to?(:deep_stringify_keys)

    staff_pending = Array(data["pending_reservations"])
    customer_pending = Array(data["pending_customer_reservations"])

    if staff_pending.present?
      count = staff_pending.size
      message = I18n.t("notifications.pending_reservation_need_confirm", number: count)
      reservation_id = params[:reservation_id].presence

      if reservation_id
        ids = staff_pending.map { |row| row["id"] }
        matched_index = ids.index { |id| id.to_s == reservation_id.to_s }
        if matched_index
          @reservations_approval_flow = true
          text = "<strong>#{matched_index + 1}/#{ids.size}</strong>"
          previous_path = matched_index.positive? ? staff_pending[matched_index - 1]["href"] : nil
          next_path = matched_index + 1 < ids.size ? staff_pending[matched_index + 1]["href"] : nil
          @notification_messages << [
            message,
            (view_context.link_to('<i class="fa fa-caret-square-left fa-2x" aria-hidden="true"></i>'.html_safe, previous_path) if previous_path),
            text,
            (view_context.link_to('<i class="fa fa-caret-square-right fa-2x" aria-hidden="true"></i>'.html_safe, next_path) if next_path),
          ].compact.join(" ")
        end
      else
        href = staff_pending.first["href"]
        text = I18n.t("notifications.pending_reservation_confirm")
        @notification_messages << "#{message} #{view_context.link_to(text, href)}"
      end
    end

    if customer_pending.present?
      count = customer_pending.size
      message = I18n.t("notifications.pending_customer_reservation_need_confirm", number: count)
      href = customer_pending.first["href"]
      text = I18n.t("notifications.pending_customer_reservation_confirm")
      @notification_messages << "#{message} #{view_context.link_to(text, href)}"
    end
  rescue StandardError => e
    Rails.logger.warn("[SchedulesController] compat notifications failed: #{e.message}")
    @notification_messages = []
    @reservations_approval_flow = false
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
    events =
      if body.is_a?(Array)
        body
      else
        Array(body&.dig("data") || body&.dig(:data))
      end
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
