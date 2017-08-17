json.savedFilterOptions @filters.map{ |filter| { label: filter.name, value: filter.id } }
json.current_saved_filter @filter.id
filterCategoryDisplaying = {}

@filter.query.each do |key, value|
  filterCategoryDisplaying[key] = true

  case key
  when "has_email"
    json.set! :has_email, value
  when "living_place"
    json.set! :livingPlaceInside, ActiveModel::Type::Boolean.new.cast(value["inside"])
    json.set! :states, value["states"]
  when "birthday"
    json.set! :birthdayQueryType, value["query_type"]

    start_date = Time.parse(value["start_date"])
    json.set! :from_dob_year, start_date.year
    json.set! :from_dob_month, start_date.month
    json.set! :from_dob_day, start_date.day

    if value["end_date"]
      end_date = Time.parse(value["end_date"])
      json.set! :to_dob_year, end_date.year
      json.set! :to_dob_month, end_date.month
      json.set! :to_dob_day, end_date.day
    end
  when "reservation"
    json.set! :reservationDateQueryType, value["query_type"]
    json.set! :hasReservation, ActiveModel::Type::Boolean.new.cast(value["has_reservation"])

    start_date = Time.parse(value["start_date"])
    json.set! :from_reservation_year, start_date.year
    json.set! :from_reservation_month, start_date.month
    json.set! :from_reservation_day, start_date.day

    if value["end_date"]
      end_date = Time.parse(value["end_date"])
      json.set! :to_reservation_year, end_date.year
      json.set! :to_reservation_month, end_date.month
      json.set! :to_reservation_day, end_date.day
    end

    if value["menu_ids"]
      filterCategoryDisplaying["menu_ids"] = true
      json.set! :menu_ids, value["menu_ids"]
    end

    if value["staff_ids"]
      filterCategoryDisplaying["staff_ids"] = true
      json.set! :staff_ids, value["staff_ids"]
    end

    if value["states"]
      filterCategoryDisplaying["reservationBeforeCheckedInStates"] = true if (Reservation::BEFORE_CHECKED_IN_STATES && value["states"]).present?
      filterCategoryDisplaying["reservationAfterCheckedInStates"] = true if (Reservation::AFTER_CHECKED_IN_STATES && value["states"]).present?
      json.set! :reservation_states, value["states"]
    end

    if !value["with_warnings"].nil?
      filterCategoryDisplaying["reservation_with_warnings"] = true
      json.set! :reservation_with_warnings, value["with_warnings"]
    end
  else
    json.set! key, value
  end
end

json.filterCategoryDisplaying filterCategoryDisplaying
