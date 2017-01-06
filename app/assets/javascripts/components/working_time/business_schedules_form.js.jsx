"use strict";

UI.define("WorkingTime.BusinessScheduleForm", function() {
  var BusinessScheduleForm = React.createClass({
    getInitialState: function() {
      return {
      }
    },

    render: function() {
      return (
        <div>
          <h3>{this.props.shop.name} 勤務日時</h3>
          <div id="parttime" className="formRow">
            <ul className="tableTTL">
              <li className="rowTTL">{this.props.dayLabel}</li>
              <li className="inOut">{this.props.inOutLabel}</li>
              <li className="startTime">{this.props.startLabel}</li>
              <li className="endsTime">{this.props.endLabel}</li>
            </ul>
            <div id="workingTime" className="formRow">
              { this.props.wdays.map(function(wday, day_index) {
                var schedule = _.find(this.props.wdays_business_schedules, function(business_schedule) {
                  return business_schedule.day_of_week == day_index
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
                      defaultValue={day_index} />

                    <dd className="inOut">
                      <input
                        type="checkbox"
                        className="BTNinout"
                        id={`shop${this.props.shop.id}-day${day_index}`}
                        name={`business_schedules[${this.props.shop.id}][${wday}][business_state]`}
                        defaultValue="opened"
                        defaultChecked={schedule ? schedule.business_state == "opened" : ""}
                      />
                      <label htmlFor={`shop${this.props.shop.id}-day${day_index}`}></label>
                    </dd>
                    <dd className="startTime">
                      <input
                        type="time"
                        name={`business_schedules[${this.props.shop.id}][${wday}][start_time]`}
                        size="20"
                        defaultValue={schedule ? moment(schedule.start_time).tz(this.props.timezone).format("HH:mm") : ""}
                         />
                    </dd>
                    <dd classNameName="endsTime">
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
          </div>
        </div>
      );
    }
  });

  return BusinessScheduleForm;
});
