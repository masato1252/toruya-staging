# frozen_string_literal: true

if @time_ranges
  json.start_time_restriction @time_ranges.first.to_fs(:time)
  json.end_time_restriction @time_ranges.last.to_fs(:time)
end
