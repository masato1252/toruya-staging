//= require "components/working_time/business_schedules_form"

"use strict";

UI.define("WorkingTime.StaffForm", function() {
  var StaffForm = React.createClass({
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

    renderModeView: function() {
      if (this.props.mode == "working_schedules") {
        return (
          <div>
            <h3>勤務日時<strong>必須項目</strong></h3>
            <div id="belong" className="formRow">
              {
                this.props.shops.map(function(shop) {
                  return (
                    <div key={`full-time-${shop.id}`}>
                      <dl className="checkbox">
                        <dd>
                          <input type="checkbox" name="shopSelect" id={`shop${shop.id}`} checked="" />
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
            {
              this.partTimeShops().map(function(shop) {
                return (
                  <div key={`partTimeShops-${shop.id}`}>
                    <h3>{shop.name} 勤務日時</h3>
                    <div id="tempHoliday" className="formRow" key={`shop-${shop.id}-schedule-setting`}>
                      <dl className="formTTL"
                        onClick={this.toggleSchedule.bind(
                          this, `business_schedules_${shop.id}`)
                        }>
                        <dt>固定日程</dt>
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
                  </div>
                );
              }.bind(this))
            }
          </div>
        );
      }
      else if (this.props.mode == "holiday_schedules") {
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
        );
      }
    },

    render: function() {
      return (
        <form action={this.props.saveStaffPath} accept-charset="UTF-8" method="post" data-behavior="dirty-form">
          <input name="utf8" type="hidden" value="✓" />
          <input type="hidden" name="_method" value="patch" />
          <input type="hidden" name="authenticity_token" value={this.props.formAuthenticityToken} />
          <h3>{this.props.nameLabel}</h3>

          <div id="staffInfo" className="formRow">
            <dl>
              <dd className="familyName"><input type="text" defaultValue={this.props.staff.last_name} disabled /></dd>
              <dd className="firstName"><input type="text" defaultValue={this.props.staff.first_name} disabled /></dd>
            </dl>
          </div>
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
