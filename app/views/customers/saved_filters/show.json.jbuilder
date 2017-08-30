json.savedFilterOptions @filters.map{ |filter| { label: filter.name, value: filter.id } }
json.current_saved_filter_id @filter.id
json.current_saved_filter_name @filter.name

json.partial! "customers/filter/query_conditions", query: @filter.query

