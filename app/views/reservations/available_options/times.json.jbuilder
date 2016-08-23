if @time_ranges
  json.start_time_restriction @time_ranges.first.to_s(:time)
  json.end_time_restriction @time_ranges.last.to_s(:time)
end
