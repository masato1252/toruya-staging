//= require "components/working_time/business_schedules_form"

"use strict";

UI.define("WorkingTime.StaffForm", function() {
  var StaffForm = React.createClass({
    getInitialState: function() {
      return {
        shops: this.props.shops,
        fullTimeShops: this.props.fullTimeShops
      }
    },

    selectedSchedule: function(shop_id) {
      return _.find(this.props.fullTimeSchedules, function(schedule) {
        return `${schedule.shop_id}` == `${shop_id}` }
      )
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

    render: function() {
      return (
        <form action={this.props.saveStaffPath} accept-charset="UTF-8" method="post">
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

          <h3>勤務日時<strong>必須項目</strong></h3>
          <div id="working" className="formRow">
            {
              this.props.shops.map(function(shop) {
                return (
                  <dl key={`full-time-${shop.id}`}>
                    <dt>{shop.name}</dt>
                    <dd>
                      <input
                        type="checkbox"
                        className="BTNalwaysIN"
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
                );
              }.bind(this))
            }
          </div>
          {
            this.partTimeShops().map(function(shop) {
              return (
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
              );
            }.bind(this))
          }
          <h3>臨時休暇</h3>
          <UI.CustomSchedules
            customSchedules={this.props.customSchedules}
            dateLabel={this.props.dateLabel}
            startTimeLabel={this.props.startTimeLabel}
            endTimeLabel={this.props.endTimeLabel}
            reasonOfClosingLabel={this.props.reasonOfClosingLabel}
            newClosingBtn={this.props.newClosingBtn}
            closingReason={this.props.closingReason}
            deleteBtn={this.props.deleteBtn}
          />

          <div id="footerav">
          </div>
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
