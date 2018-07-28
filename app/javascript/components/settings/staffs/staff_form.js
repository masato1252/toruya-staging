"use strict";

import React from "react";
import "whatwg-fetch";
import 'url-search-params-polyfill';
import ProcessingBar from "../../shared/processing_bar.js";

class SettingsStaffFormfields extends React.Component {
  state = {
    staffShopOptions: this.props.staffShopOptions,
    shopInvisible: {},
    staffAccountLevel: this.props.staffAccountLevel,
    staffAccountEmail: this.props.staffAccountEmail
  };

  swithStaffAccountLevel = (event) => {
    this.setState({staffAccountLevel: event.target.value});
  };

  onHandleStaffChange = (event) => {
    this.setState({staffAccountEmail: event.target.value});
  };

  renderWorkShops = () => {
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
  };

  selectedStaffShopOption = (shop_id) => {
    return _.find(this.state.staffShopOptions, function(option) {
      return option.shop_id == shop_id
    });
  };

  workingShopOptions = () => {
    return _.filter(this.state.staffShopOptions, function(option) {
      return option.work_here
    })
  };

  handleStaffWorkOption = (event) => {
    var matchedOption = this.selectedStaffShopOption(event.target.dataset.value)
    matchedOption.work_here = !matchedOption.work_here;

    this.setState({staffShopOptions: this.state.staffShopOptions});
  };

  toggleStaffShopView = (shopId) => {
    if (this.state.shopInvisible[shopId]) {
      this.state.shopInvisible[shopId] = false;
    }
    else {
      this.state.shopInvisible[shopId] = true;
    }

    this.setState(this.state.shopInvisible);
  };

  renderStaffSchedulePermission = () => {
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
  };

  resendStaffAccountEmail = async () => {
    if (!this.state.staffAccountEmail) return;

    try {
      this.setState({ processing: true });

      const url = new URL(this.props.resendStaffActivationEmailUrl);
      url.search = new URLSearchParams({
        id: this.props.staffId,
        email: this.state.staffAccountEmail,
        level: this.state.staffAccountLevel,
      });

      const response = await fetch(url, {
        credentials: "same-origin"
      })

      if (response.ok) {
        location.reload()
      } else if (response.status === 422) {
        const err = await response.json();
        throw new Error(err.message);
      } else {
        throw new Error(response.statusText);
      }

      this.setState({ processing: false });
    }
    catch (err) {
      this.setState({ processing: false });
      alert(err.message)
    }
  };

  render() {
    return (
      <div>
        <ProcessingBar processing={this.state.processing} processingMessage={this.props.processingMessage} />
        <h3>{this.props.staffAccountTitle}<strong>必須項目</strong></h3>
        <div>
          {this.props.staffAccountGmailHint}
        </div>
        <div id="staffAccount" className="formRow">
          <dl>
            <dt>{this.props.staffAccountEmailLabel}</dt>
            <dd>
              <input
                type="text"
                name="staff_account[email]"
                id="staff_account_email"
                value={this.state.staffAccountEmail || ""}
                onChange={this.onHandleStaffChange}
                placeholder={this.props.staffAccountEmailLabel} size="40" />
                {this.props.isStaffPersisted && (
                  <div
                    className={`resend btn btn-tarco ${this.state.staffAccountEmail ? "" : "disabled"}`}
                    onClick={this.resendStaffAccountEmail}>
                    {this.props.resendActivationEmailBtnLabel}
                  </div>
                )}
                {
                  this.props.isStaffPersisted && this.props.staffAccountIsPending && <span className="label label-warning">{this.props.pendingState}</span>
                }
            </dd>
          </dl>
          <dl>
            <dt>{this.props.staffAccountCapabilityLabel}</dt>
            <dd>
              <div className="BTNselect">
                <div>
                  <input id="accountCapability1"
                    className="BTNselect"
                    type="radio"
                    defaultValue="staff"
                    name="staff_account[level]"
                    checked={this.state.staffAccountLevel == "staff"}
                    onChange={this.swithStaffAccountLevel}
                    />
                  <label htmlFor="accountCapability1"><span>{this.props.staffAccountStaffLevelLabel}</span></label>
                </div>
                <div>
                  <input id="accountCapability2"
                    className="BTNselect"
                    type="radio"
                    defaultValue="manager"
                    name="staff_account[level]"
                    checked={this.state.staffAccountLevel == "manager"}
                    onChange={this.swithStaffAccountLevel}
                    />
                  <label htmlFor="accountCapability2"><span>{this.props.staffAccountManagerLevelLabel}</span></label>
                </div>
              </div>
            </dd>
          </dl>
        </div>
        {!this.props.staffAccountIsPending && (
          <div>
            <h3>{this.props.shopLabel}<strong>必須項目</strong></h3>
            <div id="belong" className="formRow">
              <input type="hidden" name="staff[shop_ids][]" value="" />
              {this.renderWorkShops()}
            </div>
            {this.state.staffAccountLevel == "staff" && (
              <div>
                {this.workingShopOptions().length ? <h3>{this.props.workingSettingTitle}</h3> : null}
                {this.workingShopOptions().length ? (
                  <div className="formRow">
                    {this.renderStaffSchedulePermission()}
                  </div>
                ) : null}
              </div>
            )}
          </div>
        )}
      </div>
    );
  }
};

export default SettingsStaffFormfields;
