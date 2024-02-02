import React, { useState, useEffect } from "react";
import _ from "lodash";
import { UsersServices } from "user_bot/api";
import mergeArrayOfObjects from "libraries/merge_array_of_objects";

const useSchedules = ({ business_owner_id, date }) => {
  const [schedules, setSchedules] = useState({
    available_booking_dates: [],
    holiday_dates: [],
    reservation_dates: [],
    working_dates: [],
    personal_schedule_dates: []
  })

  useEffect(() => {
    fetchSchedules()
  }, [date.year(), date.month()])

  const fetchSchedules = async () => {
    const [error, response] = await UsersServices.schedules({ business_owner_id: business_owner_id, date: date.format("YYYY-MM-DD") });

    setSchedules(mergeArrayOfObjects(schedules, response.data))
  }

  return schedules;
}

export default useSchedules;
