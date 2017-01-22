//= require "components/schedules/custom_schedule_fields"

"use strict";

UI.define("CustomSchedules", function() {
  var CustomSchedules = React.createClass({
    getDefaultProps: function() {
      open: false
    },

    getInitialState: function() {
      return ({
        start_time_date_part: "",
        start_time_time_part: "",
        end_time_time_part: "",
        reason: "",
        customSchedules: this.props.customSchedules
      });
    },

    _handleChange: function(event) {
      this.setState({[event.target.name]: event.target.value})
    },

    _isValidCustomSchedule: function() {
      return (this.state.start_time_date_part && this.state.start_time_time_part && this.state.end_time_time_part);
    },

    _handleAddRow: function(event) {
      event.preventDefault();

      if (!this._isValidCustomSchedule()) { return; }

      var customSchedules = this.state.customSchedules.slice(0)
      customSchedules.push({startTimeDatePart: this.state.start_time_date_part,
                            startTimeTimePart: this.state.start_time_time_part,
                            endTimeTimePart: this.state.end_time_time_part,
                            reason: this.state.reason})
      this.setState({
        customSchedules: customSchedules,
        start_time_date_part: "",
        start_time_time_part: "",
        end_time_time_part: "",
        reason: ""
      })
    },

    render: function() {
      return (
      <div id="tempHoliday" className="formRow">
        <ul className="tableTTL">
          <li className="date">{this.props.dateLabel}</li>
          <li className="startTime">{this.props.startTimeLabel}</li>
          <li className="endTime">{this.props.endTimeLabel}</li>
          {this.props.open ? null : (
            <li className="closeReason">{this.props.reasonOfClosingLabel}</li>
          )}
        </ul>
        <dl>
          <dt>
            <UI.Common.DatepickerField
              date={this.state.start_time_date_part}
              dataName="start_time_date_part"
              handleChange={this._handleChange}
            />
          </dt>
          <dd className="startTime">
            <input type="time" name="start_time_time_part" value={this.state.start_time_time_part} size="20" onChange={this._handleChange} />
          </dd><dd className="endTime">
            <input type="time" name="end_time_time_part" value={this.state.end_time_time_part} size="20" onChange={this._handleChange} />
            </dd>
          {this.props.open ? null : (
            <dd className="closeReason">
              <input type="text" name="reason" placeholder={this.props.closingReason} value={this.state.reason} size="20" onChange={this._handleChange} />
            </dd>
          )}
          <dd className="add">
            <a href="#" className={`BTNtarco ${this._isValidCustomSchedule() ? "" : "disabled"}`} onClick={this._handleAddRow}>{this.props.newClosingBtn}</a>
          </dd>
          </dl>
         {this.state.customSchedules.map(function(schedule, i) {
           return <UI.CustomScheduleFields key={i}
             schedule={schedule}
             deleteBtn={this.props.deleteBtn}
             open={this.props.open}
             closingReason={this.props.closingReason}
           />
         }.bind(this))}
      </div>
      );
    }
  });

  return CustomSchedules;
});
