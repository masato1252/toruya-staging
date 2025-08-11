"use strict";

import React, { useEffect, useState } from "react";
import { ReservationServices } from "components/user_bot/api"
import I18n from 'i18n-js/index.js.erb';

const ScheduleModal = ({i18n, selectedDate, props}) => {
  const [body, setBody] = useState("")

  useEffect(() => {
    fetchSchedules()
  }, [selectedDate])

  const fetchSchedules = async () => {
    if (!selectedDate) return;

    const params = {
      reservation_date: selectedDate
    }

    const [error, response] = await ReservationServices.schedule({ business_owner_id: props.business_owner_id, shop_id: props.reservation_form.shop.id, params })
    setBody(response.data)
  }

  return (
    <div className="modal fade" id="schedule-modal" tabIndex="-1" role="dialog">
      <div className="modal-dialog" role="document">
        <div className="modal-content">
          <div className="modal-header">
            {i18n.calendar}
          </div>
          <div className="schedule-dashboard">
            <div className="schedule-dates">
              <a href="#" className="btn btn-yellow btn-icon calendar-btn" onClick={() => {
                $("#calendar-modal").modal("show");
                $("#schedule-modal").modal("hide");
              }}
              >
                <i className="fa fa-calendar-alt fa-2x"></i>
                <div className="calendar-hint">
                  {I18n.t("user_bot.dashboards.schedules.calendar_hint")}
                </div>
              </a>
            </div>
          </div>

          <div className="modal-body extend scrollable" dangerouslySetInnerHTML={{ __html: body }} />
          <div className="modal-footer centerize">
            <button className="btn btn-yellow" onClick={() => { $("#schedule-modal").modal("hide"); }}>
              {I18n.t("user_bot.dashboards.reservation.book_this_date")}
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}

export default ScheduleModal;
