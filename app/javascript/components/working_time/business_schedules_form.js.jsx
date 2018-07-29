"use strict";

import React from "react";
import _ from "underscore";

var moment = require('moment-timezone');

class WorkingTimeBusinessScheduleForm extends React.Component {
  render() {
    return (
      <div id="workingTime">
        {
          this.props.wdays.map(function(wday, day_index) {
            var wday_index = (day_index + 1)%7;
            var schedule = _.find(this.props.wdays_business_schedules, function(business_schedule) {
              return business_schedule.day_of_week == wday_index
            })

          return (
            <dl key={`shop-${this.props.shop.id}-${wday}`}>
              <dt>{wday}</dt>
              <input
                type="hidden"
                name={`business_schedules[${this.props.shop.id}][${wday}][id]`}
                defaultValue={schedule ? schedule.id : ""} />
              <input
                type="hidden"
                name={`business_schedules[${this.props.shop.id}][${wday}][day_of_week]`}
                defaultValue={wday_index} />

              <dd className="inOut">
                <input
                  type="checkbox"
                  className="BTNinout"
                  id={`shop${this.props.shop.id}-day${wday_index}`}
                  name={`business_schedules[${this.props.shop.id}][${wday}][business_state]`}
                  defaultValue="opened"
                  defaultChecked={schedule ? schedule.business_state == "opened" : ""}
                />
                <label htmlFor={`shop${this.props.shop.id}-day${wday_index}`}></label>
              </dd>
              <dd className="startTime">
                <input
                  type="time"
                  name={`business_schedules[${this.props.shop.id}][${wday}][start_time]`}
                  size="20"
                  defaultValue={schedule ? moment(schedule.start_time).tz(this.props.timezone).format("HH:mm") : ""}
                   />
              </dd>
              <dd className="endsTime">
                <input
                  type="time"
                  name={`business_schedules[${this.props.shop.id}][${wday}][end_time]`}
                  size="20"
                  defaultValue={schedule ? moment(schedule.end_time).tz(this.props.timezone).format("HH:mm") : ""}
                />
              </dd>
            </dl>
          )
        }.bind(this))}
      </div>
    );
  }
};

export default WorkingTimeBusinessScheduleForm;
