"use strict";

import React from "react";
import _ from "underscore";
import "whatwg-fetch";
import 'url-search-params-polyfill';
import ProcessingBar from "../../../shared/processing_bar.js";

class SettingsStaffFormfields extends React.Component {
  state = {
    staffShopOptions: this.props.staffShopOptions,
    contactGroupOptions: this.props.contactGroupOptions,
    shopInvisible: {},
    staffAccountEmail: this.props.staffAccountEmail
  };

  onHandleStaffChange = (event) => {
    this.setState({staffAccountEmail: event.target.value});
  };

  renderWorkShops = () => {
    return (
      this.state.staffShopOptions.map(function(option) {
        return (
          <dl className="checkbox shop-permission" key={`shop-${option.shop_id}`}>
            <dd>
              <input
                type="checkbox"
                id={`shop-${option.shop_id}`}
                name="staff[shop_ids][]"
                value={option.shop_id}
                data-value={option.shop_id}
                checked={option.work_here}
                onChange={this.handleStaffWorkOption.bind(this, "shop")}
                />
              <label htmlFor={`shop-${option.shop_id}`}>
                {option.name}
              </label>
              </dd>
              {
                option.work_here && (
                  <dd>
                    <div className="BTNselect">
                      <div>
                        <input id={`accountCapability-shop-${option.shop_id}-1`}
                          className="BTNselect"
                          type="radio"
                          defaultValue="staff"
                          data-value={option.shop_id}
                          checked={this.selectedStaffShopOption(option.shop_id)["level"] == "staff"}
                          onChange={this.handleStaffWorkOption.bind(this, "staff")}
                          name={`shop_staff[${option.shop_id}][level]`}
                          />
                        <label className="radio-label" htmlFor={`accountCapability-shop-${option.shop_id}-1`}><span>{this.props.staffAccountStaffLevelLabel}</span></label>
                      </div>
                      <div>
                        <input id={`accountCapability-shop-${option.shop_id}-2`}
                          className="BTNselect"
                          type="radio"
                          defaultValue="manager"
                          data-value={option.shop_id}
                          checked={this.selectedStaffShopOption(option.shop_id)["level"] == "manager"}
                          onChange={this.handleStaffWorkOption.bind(this, "manager")}
                          name={`shop_staff[${option.shop_id}][level]`}
                          />
                        <label className="radio-label" htmlFor={`accountCapability-shop-${option.shop_id}-2`}><span>{this.props.staffAccountManagerLevelLabel}</span></label>
                      </div>
                    </div>
                  </dd>
                )
              }
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

  handleStaffWorkOption = (type, event) => {
    let _this = this;
    let matchedOption = this.selectedStaffShopOption(event.target.dataset.value);

    switch(type) {
      case "shop":
        matchedOption.work_here = !matchedOption.work_here;
        break;
      default :
        matchedOption.level = type;
    }

    this.setState({staffShopOptions: this.state.staffShopOptions.slice(0)});
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
        if (option.level == "manager") { return; }

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
        level: this.props.staffAccountLevel,
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

  renderContactGroups = () => {
    return (
      this.state.contactGroupOptions.map(function(option) {
        return (
          <dl className="checkbox contact-group-permission" key={`group-${option.contact_group_id}`}>
            <dd>
              <input
                type="checkbox"
                id={`group-${option.contact_group_id}`}
                name="staff[contact_group_ids][]"
                value={option.contact_group_id}
                data-value={option.contact_group_id}
                checked={option.readable}
                onChange={this.handleGroupReadableOption.bind(this, "group")}
                />
              <label htmlFor={`group-${option.contact_group_id}`}>
                {option.name}
              </label>
              </dd>
              {
                option.readable && (
                  <dd>
                    <div className="BTNselect">
                      <div>
                        <input id={`accountCapability-group-${option.contact_group_id}-1`}
                          className="BTNselect"
                          type="radio"
                          defaultValue="reservations_only_readable"
                          data-value={option.contact_group_id}
                          checked={this.selectedContactGroupOption(option.contact_group_id)["permission"] == "reservations_only_readable"}
                          onChange={this.handleGroupReadableOption.bind(this, "reservations_only_readable")}
                          name={`contact_groups[${option.contact_group_id}][contact_group_read_permission]`}
                          />
                        <label className="radio-label" htmlFor={`accountCapability-group-${option.contact_group_id}-1`}><span>{this.props.groupReservationsOnlyReadableLabel}</span></label>
                      </div>
                      <div>
                        <input id={`accountCapability-group-${option.contact_group_id}-2`}
                          className="BTNselect"
                          type="radio"
                          defaultValue="details_readable"
                          data-value={option.contact_group_id}
                          checked={this.selectedContactGroupOption(option.contact_group_id)["permission"] == "details_readable"}
                          onChange={this.handleGroupReadableOption.bind(this, "details_readable")}
                          name={`contact_groups[${option.contact_group_id}][contact_group_read_permission]`}
                          />
                        <label className="radio-label" htmlFor={`accountCapability-group-${option.contact_group_id}-2`}><span>{this.props.groupDetailsReadableLabel}</span></label>
                      </div>
                    </div>
                  </dd>
                )
              }
          </dl>
        )
      }.bind(this))
    );
  };

  handleGroupReadableOption = (type, event) => {
    let _this = this;
    let matchedOption = this.selectedContactGroupOption(event.target.dataset.value);

    switch(type) {
      case "group":
        matchedOption.readable = !matchedOption.readable;
        break;
      default :
        matchedOption.permission = type;
    }

    this.setState({contactGroupOptions: this.state.contactGroupOptions.slice(0)});
  };

  selectedContactGroupOption = (group_id) => {
    return _.find(this.state.contactGroupOptions, function(option) {
      return option.contact_group_id == group_id
    });
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
        </div>

        {!this.props.staffAccountIsPending && (
          <div>
            <h3>{this.props.shopLabel}<strong>必須項目</strong></h3>
            <div id="belong" className="formRow">
              <input type="hidden" name="staff[shop_ids][]" value="" />
              {this.renderWorkShops()}
            </div>
            <div>
              {
                _.any(this.workingShopOptions().map((option) => option.level == "staff" )) && <h3>{this.props.workingSettingTitle}</h3>
              }
              {
                _.any(this.workingShopOptions().map((option) => option.level == "staff" )) && (
                  <div className="formRow">
                    {this.renderStaffSchedulePermission()}
                  </div>
                )
              }
            </div>
          </div>
        )}

        {!this.props.staffAccountIsPending && this.props.isAdmin &&(
          <div>
            <h3>{this.props.contactGroupsLabel}</h3>
            <div id="belong" className="formRow">
              <input type="hidden" name="staff[contact_group_ids][]" value="" />
              {this.renderContactGroups()}
            </div>
          </div>
        )}
      </div>
    );
  }
};

export default SettingsStaffFormfields;
