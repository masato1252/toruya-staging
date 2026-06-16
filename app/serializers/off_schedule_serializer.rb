# frozen_string_literal: true

class OffScheduleSerializer
  include JSONAPI::Serializer
  VISIBLE_TO_CURRENT_USER = ->(schedule) {
    Current.user&.related_user_ids&.include?(schedule.user_id)
  }

  attributes :id, :reason, :start_time_date_part, :start_time_time_part, :end_time_date_part, :end_time_time_part, :user_id, :open, :start_time, :end_time
  attribute :start_time_date_part, &:start_time_date
  attribute :start_time_time_part, &:start_time_time
  attribute :end_time_date_part, &:end_time_date
  attribute :end_time_time_part, &:end_time_time
  attribute :full_start_time, &:start_time
  attribute :full_end_time, &:end_time
  attribute :title, &:reason

  attribute :type do |schedule|
    schedule.open? ? :open_schedule : :off_schedule
  end

  attribute :time do |schedule|
    schedule.start_time
  end

  attribute :title do |schedule|
    if VISIBLE_TO_CURRENT_USER.call(schedule)
      schedule.reason.presence || I18n.t("common.off_schedule")
    else
      I18n.t("user_bot.dashboards.schedules.user_not_available", user_name: schedule.user.profile.name)
    end
  end

  attribute :reason do |schedule|
    if VISIBLE_TO_CURRENT_USER.call(schedule)
      schedule.reason.presence || I18n.t("common.off_schedule")
    else
      I18n.t("user_bot.dashboards.schedules.user_not_available", user_name: schedule.user.profile.name)
    end
  end

  attribute :start_date do |schedule|
    I18n.l(schedule.start_time, format: :month_day_wday)
  end

  attribute :end_date do |schedule|
    I18n.l(schedule.end_time, format: :month_day_wday)
  end

  attribute :user_name do |schedule|
    schedule.user.profile.name
  end
end
