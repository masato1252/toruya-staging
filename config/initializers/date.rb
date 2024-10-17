# frozen_string_literal: true

require 'holidays/core_extensions/date'
class Date
  include Holidays::CoreExtensions::Date

  def national_holiday?(region_locale = :tw)
    if region_locale == :tw
      TW_HOLIDAYS_MAPPING.dig(self.year, self.month)&.include?(self)
    elsif region_locale == :ja
      holiday?(:jp)
    else
      holiday?(region_locale)
    end
  end

  # Japan dependency
  def self.jp_today
    # Use default time zone(Tokyo) currently
    Time.now.in_time_zone(Rails.configuration.time_zone).to_date
  end
end

tw_holidays = YAML.load_file('config/holidays/tw.yml')
TW_HOLIDAYS = tw_holidays.values.flat_map do |year|
  year.values.flatten
end.map { |day| Date.parse(day) }

# make date become date object and set to the holidays constant
TW_HOLIDAYS_MAPPING = tw_holidays.transform_keys(&:to_i).transform_values do |months|
  months.transform_keys(&:to_i).transform_values do |days|
    days.map { |day| Date.parse(day) }
  end
end