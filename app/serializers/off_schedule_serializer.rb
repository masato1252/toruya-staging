class OffScheduleSerializer
  include FastJsonapi::ObjectSerializer

  attributes :id, :reason

  attribute :type do |_|
    :off_schedule
  end

  attribute :start_time do |schedule|
    schedule.start_time.to_s(:time)
  end

  attribute :end_time do |schedule|
    schedule.end_time.to_s(:time)
  end

  attribute :time do |schedule|
    schedule.start_time
  end

  attribute :reason do |schedule|
    schedule.reason.presence || I18n.t("common.off_schedule")
  end
end
