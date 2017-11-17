"use strict";

import React from "react";
import "./business_schedules_form.js";
import "../schedules/custom_schedules.js";

var createReactClass = require('create-react-class');

UI.define("WorkingTime.StaffForm", function() {
  var StaffForm = createReactClass({
    getInitialState: function() {
      return {
        shops: this.props.shops,
        fullTimeShops: this.props.fullTimeShops,
        scheduleDisplaying: {}
      }
    },

    componentDidMount: function() {
      UI.DirtyFormHandler.init();
    },

    selectedSchedule: function(shop_id) {
      return _.find(this.props.fullTimeSchedules, function(schedule) {
        return `${schedule.shop_id}` == `${shop_id}` }
      )
    },

    _isAllShopFullTime: function() {
      var full_time_shop_ids = _.pluck(this.state.fullTimeShops, "id")

      return full_time_shop_ids.length == this.props.shops.length;
    },

    _isFullTimeShop: function(shop_id) {
      var full_time_shop_ids = _.pluck(this.state.fullTimeShops, "id")

      return _.contains(full_time_shop_ids, parseInt(shop_id));
    },

    handleShopFullTime: function(event) {
      var newFullTimeShops = this.state.fullTimeShops.slice(0);
      var newFullTimeShop;

      if (this._isFullTimeShop(event.target.dataset.value)) {
        newFullTimeShops = _.reject(newFullTimeShops, function(shop) {
          return `${shop.id}` == event.target.dataset.value
        })
      }
      else {
        newFullTimeShop = _.find(this.props.shops, function(shop) {
          return `${shop.id}` == event.target.dataset.value
        })

        newFullTimeShops.push(newFullTimeShop)
      }

      this.setState({fullTimeShops: newFullTimeShops});
    },

    partTimeShops: function() {
      var shops = this.props.shops.slice(0);

      return _.reject(shops, function(shop) {
        return this._isFullTimeShop(shop.id)
      }.bind(this))
    },

    toggleSchedule: function(scheduleId) {
      if (this.state.scheduleDisplaying[scheduleId]) {
        this.state.scheduleDisplaying[scheduleId] = false;
      }
      else {
        this.state.scheduleDisplaying[scheduleId] = true;
      }

      this.setState(this.state.scheduleDisplaying);
    },

    renderFullTimeSchedules: function() {
      return (
        <div id="belong" className="formRow">
          {
            this.props.shops.map(function(shop) {
              return (
                <div key={`full-time-${shop.id}`}>
                  <dl className="checkbox">
                    <dd>
                      <label htmlFor={`shop${shop.id}`}>{shop.name}</label>
                    </dd>
                  </dl>
                  <dl className="onoffSetting">
                    <dt>常勤</dt>
                    <dd>
                      <input
                        type="checkbox"
                        className="BTNonoff"
                        id={`alwaysINshop-${shop.id}`}
                        name={`business_schedules[${shop.id}][full_time]`}
                        value="true"
                        data-value={shop.id}
                        checked={!!this._isFullTimeShop(shop.id)}
                        onChange={this.handleShopFullTime}
                        />
                      <label htmlFor={`alwaysINshop-${shop.id}`}></label>
                      <input
                        type="hidden"
                        name={`business_schedules[${shop.id}][id]`}
                        value={this.selectedSchedule(shop.id) ? this.selectedSchedule(shop.id).id : ""} />
                    </dd>
                  </dl>
                </div>
              );
            }.bind(this))
          }
        </div>
      )
    },

    renderParTimeAndTemporaySchedules: function() {
      return (
        this.partTimeShops().map(function(shop) {
          return (
            <div key={`partTimeShops-${shop.id}`}>
              {
                this.regularWorkingTimePermission || this.props.temporaryWorkingTimePermission ? (
                  <h3>{shop.name} 勤務スタイル</h3>
                ) : null
              }
              {
                this.props.regularWorkingTimePermission || this.props.temporaryWorkingTimePermission ? (
                  <div id="tempHoliday" className="formRow" key={`shop-${shop.id}-schedule-setting`}>
                    {
                      this.props.regularWorkingTimePermission ? (
                        <div>
                          <dl className="formTTL"
                            onClick={this.toggleSchedule.bind(
                              this, `business_schedules_${shop.id}`)
                            }>
                            <dt>固定勤務</dt>
                            <dd>
                              {
                                this.state.scheduleDisplaying[`business_schedules_${shop.id}`] ? (
                                  <i className="fa fa-minus-square-o" aria-hidden="true"></i>
                                ) : (
                                  <i className="fa fa-plus-square-o" aria-hidden="true"></i>
                                )
                              }
                            </dd>
                          </dl>
                          {
                            this.state.scheduleDisplaying[`business_schedules_${shop.id}`] ? (
                              <UI.WorkingTime.BusinessScheduleForm
                                key={`schedule-${shop.id}`}
                                timezone={this.props.timezone}
                                shop={shop}
                                wdays={this.props.wdays}
                                wdays_business_schedules={this.props.wdaysBusinessSchedulesByShop[`${shop.id}`]}
                                dayLabel={this.props.dayLabel}
                                inOutLabel={this.props.inOutLabel}
                                startLabel={this.props.startLabel}
                                endLabel={this.props.endLabel}
                                />
                            ) : null
                          }
                        </div>

                      ) : null
                    }

                    {
                      this.props.temporaryWorkingTimePermission ? (
                        <div>
                          <dl className="formTTL"
                            onClick={this.toggleSchedule.bind(
                              this, `temp_working_schedules_${shop.id}`)
                            }>
                            <dt>臨時出勤</dt>
                            <dd>
                              {
                                this.state.scheduleDisplaying[`temp_working_schedules_${shop.id}`] ? (
                                  <i className="fa fa-minus-square-o" aria-hidden="true"></i>
                                ) : (
                                  <i className="fa fa-plus-square-o" aria-hidden="true"></i>
                                )
                              }
                            </dd>
                          </dl>
                          {
                            this.state.scheduleDisplaying[`temp_working_schedules_${shop.id}`] ? (
                              <UI.CustomSchedules
                                customSchedules={this.props.openedCustomSchedulesByShop[`${shop.id}`] || []}
                                shopId={shop.id}
                                dateLabel={this.props.dateLabel}
                                startTimeLabel={this.props.startTimeLabel}
                                endTimeLabel={this.props.endTimeLabel}
                                reasonOfClosingLabel={this.props.reasonOfClosingLabel}
                                newClosingBtn={this.props.newClosingBtn}
                                closingReason={this.props.closingReason}
                                deleteBtn={this.props.deleteBtn}
                                calendarfieldPrefix={`temp_working_schedules_${shop.id}`}
                                fromStaff={true}
                                open={true}
                                />
                            ) : null
                          }
                        </div>
                      ) : null
                    }
                  </div>
                ) : null
              }
            </div>
          );
        }.bind(this))
      )
    },

    renderHolidaySchedules: function() {
      return (
        <div>
          <h3>休暇</h3>
          <div id="tempHoliday" className="formRow">
            <dl className="formTTL"
              onClick={this.toggleSchedule.bind(this, "temp_leaving_schedules")}>
              <dt>休暇を設定する</dt>
              <dd>
              {
                this.state.scheduleDisplaying["temp_leaving_schedules"] ? (
                  <i className="fa fa-minus-square-o" aria-hidden="true"></i>
                ) : (
                  <i className="fa fa-plus-square-o" aria-hidden="true"></i>
                )
              }
              </dd>
            </dl>
            {
              this.state.scheduleDisplaying["temp_leaving_schedules"] ? (
                <UI.CustomSchedules
                  customSchedules={this.props.closedCustomSchedules}
                  dateLabel={this.props.dateLabel}
                  startTimeLabel={this.props.startTimeLabel}
                  endTimeLabel={this.props.endTimeLabel}
                  reasonOfClosingLabel={this.props.reasonOfClosingLabel}
                  newClosingBtn={this.props.newClosingBtn}
                  closingReason={this.props.closingReason}
                  deleteBtn={this.props.deleteBtn}
                  calendarfieldPrefix="temp_leaving_schedule"
                  fromStaff={true}
                  open={false}
                />
              ) : null
            }
          </div>
        </div>

      )
    },

    renderModeView: function() {
      if (this.props.mode == "working_schedules") {
        return (
          <div>
            <h3>勤務スタイル<strong>必須項目</strong></h3>
            { this.props.fullTimePermission ? this.renderFullTimeSchedules() : null }
            { this.renderParTimeAndTemporaySchedules() }
          </div>
        )
      }
      else if (this.props.mode == "holiday_schedules") {
        return (
          this.props.holidayPermission ? this.renderHolidaySchedules() : null
        )
      }
    },

    render: function() {
      return (
        <form action={this.props.saveStaffPath} acceptCharset="UTF-8" method="post" data-behavior="dirty-form">
          <input name="utf8" type="hidden" value="✓" />
          <input type="hidden" name="_method" value="patch" />
          <input type="hidden" name="authenticity_token" value={this.props.formAuthenticityToken} />
          <input type="hidden" name="mode" value={this.props.mode} />
          {this.renderModeView()}

          <ul id="footerav">
            <li><a href={this.props.cancelPath} className="BTNtarco">{this.props.cancelBtn}</a></li>
            <li><input type="submit" className="BTNyellow" value="保存" /></li>
          </ul>
        </form>
      )
    }
  });

  return StaffForm;
});

export default UI.WorkingTime.StaffForm;
