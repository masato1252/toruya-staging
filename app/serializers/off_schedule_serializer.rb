# frozen_string_literal: true

class OffScheduleSerializer
  include JSONAPI::Serializer

  attributes :id, :reason, :start_time_date_part, :start_time_time_part, :end_time_date_part, :end_time_time_part, :user_id, :open
  attribute :start_time_date_part, &:start_time_date
  attribute :start_time_time_part, &:start_time_time
  attribute :end_time_date_part, &:end_time_date
  attribute :end_time_time_part, &:end_time_time

  attribute :type do |_|
    :off_schedule
  end

  attribute :time do |schedule|
    schedule.start_time
  end

  attribute :reason do |schedule|
    schedule.reason.presence || I18n.t("common.off_schedule")
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
