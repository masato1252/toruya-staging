//= require "components/schedules/custom_schedule_fields"

"use strict";

UI.define("CustomSchedules", function() {
  var CustomSchedules = React.createClass({
    getInitialState: function() {
      return ({
        start_time_date_part: moment().format("YYYY-MM-DD"),
        start_time_time_part: "00:00",
        end_time: "23:59",
        reason: "",
        customSchedules: this.props.customSchedules
      });
    },

    _handleChnage: function(event) {
      this.setState({[event.target.name]: event.target.value})
    },

    _isValidCustomSchedule: function() {
      return (this.state.start_time_date_part && this.state.start_time_time_part && this.state.end_time);
    },

    _handleAddRow: function(event) {
      event.preventDefault();

      if (!this._isValidCustomSchedule()) { return; }

      var customSchedules = this.state.customSchedules.slice(0)
      customSchedules.push({startTimeDatePart: this.state.start_time_date_part,
                            startTimeTimePart: this.state.start_time_time_part,
                            endTime: this.state.end_time,
                            reason: this.state.reason})
      this.setState({
        customSchedules: customSchedules,
        start_time_date_part: moment().format("YYYY-MM-DD"),
        start_time_time_part: "00:00",
        end_time: "23:59",
        reason: ""
      })
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
            <input type="time" name="start_time_time_part" defaultValue="00:00" value={this.state.start_time_time_part} size="20" onChange={this._handleChnage} />
          </dd><dd className="endTime">
            <input type="time" name="end_time" defaultValue="23:59" value={this.state.end_time} size="20" onChange={this._handleChnage} />
          </dd>
          <dd className="closeReason">
            <input type="text" name="reason" placeholder="Write your reason(optional)" value={this.state.reason} size="40" onChange={this._handleChnage} />
          </dd>
          <dd className="add">
            <a href="#" className={`BTNtarco ${this._isValidCustomSchedule() ? "" : "disabled"}`} onClick={this._handleAddRow}>ADD a Row</a>
          </dd>
          </dl>
         {this.state.customSchedules.map(function(schedule, i) {
           return <UI.CustomScheduleFields key={i} schedule={schedule} />
         })}
      </div>
      );
    }
  });

  return CustomSchedules;
});
