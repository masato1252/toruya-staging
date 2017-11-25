filterCategoryDisplaying = {}

query.each do |key, value|
  filterCategoryDisplaying[key] = true

  case key
  when "has_email"
    json.set! :has_email, value
  when "living_place"
    json.set! :livingPlaceInside, ActiveModel::Type::Boolean.new.cast(value["inside"])
    json.set! :states, value["states"]
  when "birthday"
    json.set! :birthdayQueryType, value["query_type"]

    if value["start_date"]
      start_date = Time.parse(value["start_date"])
      json.start_dob_date start_date.to_s(:date)
    end

    if value["end_date"]
      end_date = Time.parse(value["end_date"])
      json.end_dob_date end_date.to_s(:date)
    end

    if value["month"]
      json.month_of_dob value["month"]
    end
  when "reservation"
    json.set! :reservationDateQueryType, value["query_type"]
    json.set! :hasReservation, ActiveModel::Type::Boolean.new.cast(value["has_reservation"])

    start_date = Time.parse(value["start_date"])
    json.set! :start_reservation_date, start_date.to_s(:date)

    if value["end_date"]
      end_date = Time.parse(value["end_date"])
      json.set! :end_reservation_date, end_date.to_s(:date)
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
