# frozen_string_literal: true

class OffScheduleSerializer
  include JSONAPI::Serializer

  attributes :id, :reason, :start_time_date_part, :start_time_time_part, :end_time_date_part, :end_time_time_part, :user_id, :open, :start_time, :end_time
  attribute :start_time_date_part, &:start_time_date
  attribute :start_time_time_part, &:start_time_time
  attribute :end_time_date_part, &:end_time_date
  attribute :end_time_time_part, &:end_time_time
  attribute :full_start_time, &:start_time
  attribute :full_end_time, &:end_time
  attribute :title, &:reason

  attribute :type do |_|
    :off_schedule
  end

  attribute :time do |schedule|
    schedule.start_time
  end

  attribute :title do |schedule|
    schedule.reason.presence || I18n.t("common.off_schedule")
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
