"use strict";

import React from "react";
import moment from "moment-timezone";
import CommonDatepickerField from "shared/datepicker_field.js";
import { getMomentLocale } from "libraries/helper.js";

class CustomScheduleFields extends React.Component {
  constructor(props) {
    super(props);

    // Use default locale 'ja' if not provided in props
    const locale = this.props.locale || 'ja';
    moment.locale(getMomentLocale(locale));

    this.state = {
      start_time_date_part: this.props.schedule.startTimeDatePart || "",
      start_time_time_part: this.props.schedule.startTimeTimePart || "",
      end_time_time_part: this.props.schedule.endTimeTimePart || "",
      reason: this.props.schedule.reason || "",
      delete_flag: false,
      edit_mode: false
    }
  };

  _handleChange = (event) => {
    this.setState({[event.target.dataset.name]: event.target.value})
  };

  _handleDateChange = (dateChange) => {
    this.setState(dateChange)
  };

  _deleteCustomRow = (event) => {
    event.preventDefault();
    this.setState({delete_flag: !this.state.delete_flag})
  };

  _editCustomRow = (event) => {
    event.preventDefault();
    this.setState({edit_mode: !this.state.edit_mode})
  };

  render() {
    if (this.state.delete_flag) {
      return (
        <div>
          {
            this.props.schedule.id ?
            <input type="hidden" name="custom_schedules[][id]" value={this.props.schedule.id} />
            : null
          }
          {
            this.props.schedule.id ?
            <input type="hidden" name="custom_schedules[][_destroy]" defaultValue="true" />
              : null
          }
        </div>
      )
    }

    return (
      <dl>
        {
          this.props.schedule.id ?
          <input type="hidden" name="custom_schedules[][id]" value={this.props.schedule.id} />
          : null
        }
        {
          this.props.shopId ?
          <input type="hidden" name="custom_schedules[][shop_id]" value={this.props.shopId} />
          : null
        }
        <input
          type="hidden"
          name="custom_schedules[][open]"
          defaultValue={this.props.open}
          />
        <dt className="date">
          {
            this.state.edit_mode ? (
              <span>
                <CommonDatepickerField
                  date={this.state.start_time_date_part}
                  name="custom_schedules[][start_time_date_part]"
                  dataName="start_time_date_part"
                  handleChange={this._handleDateChange}
                  calendarfieldPrefix={this.props.calendarfieldPrefix}
                />
              </span>
            ) : (
              <span>
                <input
                  type="date"
                  value={this.state.start_time_date_part}
                  disabled="disabled"
                  />
                <input
                  type="hidden"
                  name="custom_schedules[][start_time_date_part]"
                  value={this.state.start_time_date_part}
                  />
                { this.state.start_time_date_part ? `(${moment(this.state.start_time_date_part).format("dd")})` : null }
                <a href="#" className="BTNtarco disabled">
                  <i className="fa fa-calendar fa-2" aria-hidden="true"></i>
                </a>
              </span>
            )
          }
        </dt>
        <dd className="startTime">
          {
            this.state.edit_mode ? (
              <input
                type="time"
                name="custom_schedules[][start_time_time_part]"
                data-name="start_time_time_part"
                value={this.state.start_time_time_part}
                size="20"
                onChange={this._handleChange} />
            ) : (
              <span>
                <input
                  type="time"
                  value={this.state.start_time_time_part}
                  disabled="disabled" />
                <input
                  type="hidden"
                  name="custom_schedules[][start_time_time_part]"
                  value={this.state.start_time_time_part} />
              </span>
            )
          }
        </dd>
        <dd>
         ~
        </dd>
        <dd className="endTime">
          {
            this.state.edit_mode ? (
              <input
                type="time"
                name="custom_schedules[][end_time_time_part]"
                data-name="end_time_time_part"
                value={this.state.end_time_time_part}
                size="20"
                onChange={this._handleChange} />
            ) : (
              <span>
                <input
                  type="time"
                  value={this.state.end_time_time_part}
                  disabled="disabled" />
                <input
                  type="hidden"
                  name="custom_schedules[][end_time_time_part]"
                  value={this.state.end_time_time_part} />
              </span>
            )
          }
        </dd>
        {this.props.open || this.props.fromStaff ? null :
          (
            this.state.edit_mode ? (
              <dd className="closeReason">
                <input
                  type="text"
                  name="custom_schedules[][reason]"
                  data-name="reason"
                  value={this.state.reason}
                  placeholder={this.props.closingReason}
                  size="20"
                  onChange={this._handleChange} />
              </dd>
            ) : (
              <dd className="closeReason">
                <span>
                  <input
                    type="text"
                    value={this.state.reason}
                    disabled="disabled" />
                  <input
                    type="hidden"
                    name="custom_schedules[][reason]"
                    value={this.state.reason} />
                </span>
              </dd>
            )
        )}
        <dd className="add function">
          <a href="#" className="BTNorange" onClick={this._deleteCustomRow}>
            {this.props.deleteBtn}
          </a>
          <a href="#" className="BTNyellow" onClick={this._editCustomRow}>
            {this.state.edit_mode ? "保存" : "編集"}
          </a>
        </dd>
      </dl>
    );
  }
};

export default CustomScheduleFields;
