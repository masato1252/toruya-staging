if @time_ranges
  json.start_time_restriction @time_ranges.first.to_s(:time)
  json.end_time_restriction @time_ranges.last.to_s(:time)
end

json.customer_max_load_capability @customer_max_load_capability || 0
json.errors @errors_with_warnings[:errors]
json.warnings @errors_with_warnings[:warnings]
