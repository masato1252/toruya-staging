# frozen_string_literal: true

require 'holidays/core_extensions/date'
class Date
  include Holidays::CoreExtensions::Date

  # Japan dependency
  def self.jp_today
    # Use default time zone(Tokyo) currently
    Time.now.in_time_zone(Rails.configuration.time_zone).to_date
  end
end
