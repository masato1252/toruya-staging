"use strict";

UI.define("Settings.Staff.Formfields", function() {
  var StaffFormfields = React.createClass({
    getInitialState: function() {
      return ({
        staffShopOptions: this.props.staffShopOptions,
        shopInvisible: {}
      });
    },

    renderWorkShops: function() {
      return (
        this.state.staffShopOptions.map(function(option) {
          return (
            <dl className="checkbox" key={`shop-${option.shop_id}`}>
              <dd>
                <input
                  type="checkbox"
                  id={`shop-${option.shop_id}`}
                  name="staff[shop_ids][]"
                  value={option.shop_id}
                  data-value={option.shop_id}
                  checked={option.work_here}
                  onChange={this.handleStaffWorkOption}
                  />
                <label htmlFor={`shop-${option.shop_id}`}>
                  {option.name}
                </label>
              </dd>
            </dl>
          )
        }.bind(this))
      );
    },

    selectedStaffShopOption: function(shop_id) {
      return _.find(this.state.staffShopOptions, function(option) {
        return option.shop_id == shop_id
      });
    },

    workingShopOptions: function() {
      return _.filter(this.state.staffShopOptions, function(option) {
        return option.work_here
      })
    },

    handleStaffWorkOption: function(event) {
      var matchedOption = this.selectedStaffShopOption(event.target.dataset.value)
      matchedOption.work_here = !matchedOption.work_here;

      this.setState({staffShopOptions: this.state.staffShopOptions});
    },

    toggleStaffShopView: function(shopId) {
      if (this.state.shopInvisible[shopId]) {
        this.state.shopInvisible[shopId] = false;
      }
      else {
        this.state.shopInvisible[shopId] = true;
      }

      this.setState(this.state.shopInvisible);
    },

    renderStaffSchedulePermission: function() {
      var view = this.workingShopOptions().map(function(option) {
          return (
            <div key={`working-shop-option-${option.shop_id}`}>
              <dl className="formTTL" onClick={this.toggleStaffShopView.bind(this, `staff_shop_settings_${option.shop_id}`)}>
                <dt>{option.name}</dt>
                <dd>
                  {
                     this.state.shopInvisible[`staff_shop_settings_${option.shop_id}`] ? (
                       <i className="fa fa-plus-square-o" aria-hidden="true"></i>
                     ) : (
                       <i className="fa fa-minus-square-o" aria-hidden="true"></i>
                     )
                  }
                </dd>
              </dl>

              {
                !this.state.shopInvisible[`staff_shop_settings_${option.shop_id}`] ? (
                  <div>
                  <dl className="onoffSetting">
                    <dt>{this.props.fullTimePermission}</dt>
                    <dd>
                      <input type="hidden" name={`shop_staff[${option.shop_id}][staff_full_time_permission]`} value="0" />
                      <input type="checkbox" className="BTNonoff"
                        id={`alwaysINshop-${option.shop_id}`}
                        name={`shop_staff[${option.shop_id}][staff_full_time_permission]`}
                        defaultValue="1"
                        defaultChecked={option.full_time_permission}
                        />
                      <label htmlFor={`alwaysINshop-${option.shop_id}`}></label>
                    </dd>
                  </dl>

                  <dl className="onoffSetting">
                    <dt>{this.props.regularWorkingTimePermission}</dt>
                    <dd>
                      <input type="hidden" name={`shop_staff[${option.shop_id}][staff_regular_working_day_permission]`} value="0" />
                      <input type="checkbox" className="BTNonoff"
                        id={`allowWork-${option.shop_id}`}
                        name={`shop_staff[${option.shop_id}][staff_regular_working_day_permission]`}
                        defaultValue="1"
                        defaultChecked={option.regular_schedule_permission}
                      />
                      <label htmlFor={`allowWork-${option.shop_id}`}></label>
                    </dd>
                  </dl>

                  <dl className="onoffSetting">
                    <dt>{this.props.temporaryWorkingTimePermission}</dt>
                    <dd>
                      <input type="hidden" name={`shop_staff[${option.shop_id}][staff_temporary_working_day_permission]`} value="0" />
                      <input type="checkbox" className="BTNonoff"
                        id={`allowTempWork-${option.shop_id}`}
                        name={`shop_staff[${option.shop_id}][staff_temporary_working_day_permission]`}
                        defaultValue="1"
                        defaultChecked={option.temporary_working_day_permission}
                      />
                      <label htmlFor={`allowTempWork-${option.shop_id}`}></label>
                    </dd>
                  </dl>
                </div>
                ) : null
              }
            </div>
          )
      }.bind(this))
      return view;
    },

    render: function() {
      return (
        <div>
          <h3>{this.props.shopLabel}<strong>必須項目</strong></h3>
          <div id="belong" className="formRow">
            <input type="hidden" name="staff[shop_ids][]" value="" />
            {this.renderWorkShops()}
          </div>
          <h3>{this.props.workingSettingTitle}</h3>
          <div className="formRow">
            {this.renderStaffSchedulePermission()}
          </div>
        </div>
      );
    }
  });

  return StaffFormfields;
});
