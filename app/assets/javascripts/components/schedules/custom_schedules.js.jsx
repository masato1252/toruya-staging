//= require "components/schedules/custom_schedule_fields"

"use strict";

UI.define("CustomSchedules", function() {
  var CustomSchedules = React.createClass({
    getInitialState: function() {
      return ({
        start_time_date_part: "",
        start_time_time_part: "",
        end_time: "",
        reason: ""
      });
    },

    _handleChnage: function(event) {
      this.setState({[event.target.name]: event.target.value})
    },

    render: function() {
      return (
      <div id="tempHoliday" className="formRow">
        <ul className="tableTTL">
          <li className="date">Date</li>
          <li className="startTime">Start Time</li>
          <li className="endTime">End Time</li>
          <li className="closeReason">Reason of closing</li>
        </ul>
        <dl>
          <dt>
            <input type="date" name="start_time_date_part" value={this.state.start_time_date_part} onChange={this._handleChnage}/>
          </dt>
          <dd className="startTime">
            <input type="time" name="start_time_time_part" value={this.state.start_time_time_part} size="20" onChange={this._handleChnage} />
          </dd><dd className="endTime">
            <input type="time" name="end_time" value={this.state.end_time} size="20" />
          </dd>
          <dd className="closeReason">
            <input type="text" name="reason" value={this.state.reason} size="40" />
          </dd>
          <dd className="add">
            <a href="" className="BTNtarco">ADD a Row</a>
          </dd>
          </dl>
         {this.props.customSchedules.map(function(schedule) {
           return <UI.CustomScheduleFields key={schedule.id} schedule={schedule} />
         })}
      </div>
      );
    }
  });

  return CustomSchedules;
});
