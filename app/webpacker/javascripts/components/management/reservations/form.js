"use strict";

import React from "react";
import { Form, Field } from "react-final-form";
import { FieldArray } from 'react-final-form-arrays'
import arrayMutators from 'final-form-arrays'
import createChangesDecorator from "final-form-calculate";
import moment from "moment-timezone";
import axios from "axios";
import _ from "lodash";
import qs from "qs";

import DateFieldAdapter from "../../shared/date_field_adapter";
import { Input } from "../../shared/components";
import CommonCustomersList from "../common/customers_list.js"
import MultipleMenuInput from "./multiple_menu_input.js"
import ReservationCustomersList from "./customers_list.js"
import { displayErrors } from "./helpers.js"

class ManagementReservationForm extends React.Component {
  constructor(props) {
    super(props);

    this.calculator = createChangesDecorator(
      {
        field: /end_time_date_part|end_time_time_part|menu_staffs_list/,
        updates: async (value, name, allValues) => {
          await this.validateReservation(allValues.reservation_form)
          return {};
        }
      },
      {
        field: /start_time_date_part/,
        updates: {
          "reservation_form[end_time_date_part]": (start_time_date_part_value, allValues) => start_time_date_part_value
        }
      },
      {
        field: /start_time_date_part|start_time_time_part|menu_staffs_list/,
        updates: async (value, name, allValues) => {
          const {
            start_time_date_part,
            start_time_time_part,
            menu_staffs_list,
          } = allValues.reservation_form;

          if (!start_time_date_part || !start_time_time_part || !_.filter(menu_staffs_list, (menu) => !!menu.menu_id).length) {
            return {}
          }

          const end_at = this.end_at(allValues.reservation_form);

          return {
            "reservation_form[end_time_date_part]": end_at.format("YYYY-MM-DD"),
            "reservation_form[end_time_time_part]": end_at.format("HH:mm")
          }
        }
      }
    )
  };

  componentDidMount() {
    this.validateReservation()
  };

  renderReservationDateTime = () => {
    const {
      start_time_restriction,
      end_time_restriction,
      end_time_date_part,
      end_time_time_part,
    } = this.reservation_form_values;
    const { is_editable, shop_name } = this.props.reservation_properties;
    const {
      details,
      date_on,
      time,
    } = this.props.i18n;
    const end_at = this.end_at();

    return (
      <div>
        <h2>
          <i className="fa fa-calendar-o" aria-hidden="true"></i>
          {details}
        </h2>
        <div id="resDateTime" className="formRow">
          <dl className="form" id="resDate">
            <dt>{date_on}</dt>
            <dd className="input">
              <Field
                name="reservation_form[start_time_date_part]"
                component={DateFieldAdapter}
                date={moment.tz(this.props.timezone).format("YYYY-MM-DD")}
                className={this.dateErrors().length ? "field-warning" : ""}
                isDisabled={!is_editable}
              />
              {
                start_time_restriction && end_time_restriction ? (
                  <div className="busHours table">
                    <div className="tableCell shopname">{shop_name}</div>
                    <div className="tableCell">{start_time_restriction}〜{end_time_restriction}</div>
                  </div>
                ) : (
                  <div className="busHours shopClose table">
                    <div className="tableCell shopname">{shop_name}</div>
                    <div className="tableCell">CLOSED</div>
                  </div>
                )
              }
              <span className="errors">
                {this.dateErrors()}
              </span>
            </dd>
          </dl>
          <dl className="form" id="resTime">
            <dt>{time}</dt>
            <dd className="input">
              <Field
                name="reservation_form[start_time_time_part]"
                type="time"
                component={Input}
                step="300"
                className={this.previousReservationOverlap() ? "field-warning" : ""}
                disabled={!is_editable}
              />
              <span className="errors">
                {this.startTimeError()}
              </span>
              〜
              {end_at && end_at.locale('en').format("hh:mm A")}
              <Field
                name="reservation_form[end_time_date_part]"
                type="hidden"
                component="input"
              />
              <Field
                name="reservation_form[end_time_time_part]"
                type="hidden"
                component={Input}
                className={this.nextReservationOverlap() ? "field-warning" : ""}
              />
              <span className="errors">
                {this.displayIntervalOverlap()}
                {this.endTimeError()}
              </span>
            </dd>
          </dl>
        </div>
      </div>
    )
  }

  renderReservationMenus = () => {
    const {
      content,
    } = this.props.i18n;
    const {
      staff_options,
      menu_group_options,
    } = this.props.reservation_properties;

    return (
      <div className="formRow res-menus">
        <dl className="form">
          <dt>{content}</dt>
          <dd className="input">
            <MultipleMenuInput
              collection_name="reservation_form[menu_staffs_list]"
              staff_options={staff_options}
              menu_options={menu_group_options}
              i18n={this.props.i18n}
              reservation_form={this.reservation_form}
              all_values={this.all_values}
            />
          </dd>
        </dl>
      </div>
    )
  }

  renderReservationMemo = () => {
    const { is_editable } = this.props.reservation_properties;
    const { memo } = this.props.i18n;

    return (
      <div id="resMemo" className="formRow">
        <dl className="form" id="resMemoRow">
          <dt>メモ</dt>
          <dd className="input">
            <Field
              name="reservation_form[memo]"
              component="textarea"
              placeholder={memo}
              rows={4}
              cols={40}
              disabled={!is_editable}
            />
          </dd>
        </dl>
      </div>
    )
  }

  _customerWording = () => {
    if (this._isMeetCustomerLimit()) {
      return "満席"
    }
    else {
      return "追加"
    }
  };

  renderCustomersList = () => {
    const {
      customers_list_label,
    } = this.props.i18n;
    const {
      is_customers_readable,
      is_editable,
    } = this.props.reservation_properties;
    const {
      customers
    } = this.reservation_form_values;

    return (
      <div id="customers">
        <h2>
          <i className="fa fa-user-plus" aria-hidden="true"></i>
          {customers_list_label}
          {is_customers_readable &&
            <a
              onClick={this.addCustomer}
              className={this._customerAddClass()}
              id="addCustomer">
              {this._customerWording()}
            </a>}
          </h2>

          <ReservationCustomersList
            collection_name="reservation_form[customers_list]"
            all_values={this.all_values}
          />
          <div id="customerLevels">
            <ul>
              <li className="regular">
                <span className="customer-level-symbol regular">
                  <i className="fa fa-address-card"></i>
                </span>
                <span>一般</span>
              </li>
              <li className="vip">
                <span className="customer-level-symbol vip">
                  <i className="fa fa-address-card"></i>
                </span>
                <span className="wording">VIP</span>
              </li>
            </ul>
          </div>
        </div>
    )
  }

  renderFooterBar = () => {
    const {
      delete_reservation,
      delete_confirmation_message,
      confirm_with_warnings,
    } = this.props.i18n;
    const {
      from_customer_id,
      from_shop_id,
    } = this.props.reservation_properties;
    const {
      submitting,
      reservation_id
    } = this.reservation_form_values;

    return (
      <footer>
        <ul id="leftFunctions" className="checkbox">
          <li>
            <Field
              name="reservation_form[rough_mode]"
              type="checkbox"
              component="input"
              id="confirm-with-errors"
            />
            <label htmlFor="confirm-with-errors">
              {confirm_with_warnings}
            </label>
          </li>
        </ul>
        <ul id="BTNfunctions">
          {reservation_id ? (
            <li>
              <a className="BTNorange"
                data-confirm={delete_confirmation_message}
                rel="nofollow"
                data-method="delete"
                href={`${this.props.path.save}?from_customer_id=${from_customer_id ? from_customer_id : ""}`}>
                <i className="fa fa-trash-o" aria-hidden="true"></i>
                {delete_reservation}
              </a>
            </li>
          ) : null
          }
          <li>
            <button
              id="BTNsave"
              className={this.otherStaffsResponsibleThisReservation() ? "BTNorange" : "BTNyellow"}
              disabled={!this._isValidToReserve() || submitting}
              onClick={(event) => {
                if (this._isValidToReserve()) {
                  this.handleSubmit(event)
                }
              }}>
              <i className="fa fa-folder-o" aria-hidden="true"></i>
              {this.renderSubmitButtonText()}
            </button>
          </li>
        </ul>
    </footer>
    )
  }

  renderSubmitButtonText = () => {
    const {
      processing,
      save,
      save_pending
    } = this.props.i18n;
    const { submitting } = this.reservation_form_values;

    if (submitting) {
      return processing;
    }
    else {
      if (this.otherStaffsResponsibleThisReservation()) {
        return save_pending;
      }
      else {
        return save;
      }
    }
  };

  onSubmit = async (event) => {
    await this.reservation_form.change("reservation_form[submitting]", true)
    $("#save-reservation-form").submit();
  }

  render() {
    return (
      <Form
        action={this.props.path.save}
        onSubmit={this.onSubmit}
        initialValues={{
          reservation_form: { ...(this.props.reservation_form) },
        }}
        mutators={{
          ...arrayMutators,
        }}
        decorators={[this.calculator]}
        render={({ handleSubmit, submitting, values, errors, form, pristine }) => {
          this.reservation_form = form;
          this.reservation_form_values = values.reservation_form
          this.all_values = values
          this.handleSubmit = handleSubmit

          return (
            <form
              action={this.props.path.save}
              id="save-reservation-form"
              onSubmit={handleSubmit}
              acceptCharset="UTF-8"
              method="post">
              <input name="utf8" type="hidden" value="✓" />
              <input type="hidden" name="authenticity_token" value={this.props.form_authenticity_token} />
              <input type="hidden" name="from_customer_id" value={this.props.reservation_properties.from_customer_id} />
              <Field name="reservation_form[id]" type="hidden" component="input" />
              { this.reservation_form_values.reservation_id ?  <input name="_method" type="hidden" value="PUT" /> : null }
              <div id="resNew" className="contents">
                <div id="resInfo" className="contBody">
                  {this.renderReservationDateTime()}
                  {this.renderReservationMenus()}
                  {this.renderReservationMemo()}
                </div>
                {this.renderCustomersList()}
              </div>
              {this.renderFooterBar()}
            </form>
          )
        }}
      />
    )
  }

  validateReservation = async (form_values = null) => {
    var _this = this;

    form_values = form_values || this.reservation_form_values;

    if (this.validateReservationCall) {
      this.validateReservationCall.cancel();
    }
    this.validateReservationCall = axios.CancelToken.source();

    if (!form_values.start_time_date_part) {
      return;
    }

    this.reservation_form.change("reservation_form[processing]", true)

    try {
      const response = await axios({
        method: "GET",
        url: this.props.path.validate_reservation,
        params: {
          reservation_form: _.pick(
            form_values,
            "reservation_id",
            "start_time_date_part",
            "start_time_time_part",
            "end_time_date_part",
            "end_time_time_part",
            "menu_staffs_list",
            "customers_list"
          ),
        },
        paramsSerializer: (params) => {
          return qs.stringify(params, {arrayFormat: 'brackets'})
        },
        responseType: "json",
        cancelToken: this.validateReservationCall.token
      })

      const result = response.data;
      this.reservation_form.change("reservation_form[start_time_restriction]", result["start_time_restriction"])
      this.reservation_form.change("reservation_form[end_time_restriction]", result["end_time_restriction"])
      this.reservation_form.change("reservation_form[errors]", result["errors"])
      this.reservation_form.change("reservation_form[warnings]", result["warnings"])
    }
    catch(err) {
      if (axios.isCancel(err)) {
        console.log('First request canceled', err.message);
      }
    }
    finally {
      this.reservation_form.change("reservation_form[processing]", false)
    }
  }

  addCustomer = async () => {
    const response = await axios({
      method: "GET",
      url: this.props.path.add_customer,
      params: {
        reservation_form: _.pick(
          this.reservation_form_values,
          "reservation_id",
          "start_time_date_part",
          "start_time_time_part",
          "end_time_date_part",
          "end_time_time_part",
          "menu_staffs_list",
          "customers_list"
        ),
      },
      paramsSerializer: (params) => {
        return qs.stringify(params, {arrayFormat: 'brackets'})
      },
      responseType: "json",
    })

    window.location = response.data.redirect_to;
  }

  startTimeError = () => {
    return displayErrors(this.reservation_form_values, ["reservation_form.start_time.invalid_time"]);
  };

  endTimeError = () => {
    return displayErrors(this.reservation_form_values, ["reservation_form.end_time.invalid_time"]);
  };

  dateErrors = () => {
    return displayErrors(this.reservation_form_values, ["reservation_form.date.shop_closed"]);
  };

  previousReservationOverlap = () => {
    return displayErrors(this.reservation_form_values, ["reservation_form.start_time.interval_too_short"]).length != 0;
  };

  nextReservationOverlap = () => {
    return displayErrors(this.reservation_form_values, ["reservation_form.end_time.interval_too_short"]).length != 0;
  };

  displayIntervalOverlap = () => {
    return displayErrors(this.reservation_form_values, ["reservation_form.start_time.interval_too_short"]) &&
      displayErrors(this.reservation_form_values, ["reservation_form.end_time.interval_too_short"])
  }

  // Not only current staff responsible for this reservation.
  otherStaffsResponsibleThisReservation = () => {
    const {
      current_user_staff_id
    } = this.props.reservation_properties;
    return this._all_staff_ids().some(staff_id => staff_id !== current_user_staff_id);
  };

  _all_staff_ids = () => {
    return _.compact(_.flatMap(this.reservation_form_values.menu_staffs_list, (menu_mapping) => menu_mapping.staff_ids).map((staff) => staff.staff_id))
  }

  _all_menu_ids = () => {
    return _.compact(_.flatMap(this.reservation_form_values.menu_staffs_list, (menu_mapping) => menu_mapping.menu_id))
  }

  _isValidToReserve = () => {
    const { is_editable } = this.props.reservation_properties;
    const {
      errors,
      warnings,
      menu_staffs_list,
      rough_mode
    } = this.reservation_form_values

    return (
      is_editable &&
      menu_staffs_list.length &&
      this._all_menu_ids().length &&
      this._all_staff_ids().length &&
      (rough_mode ? !errors : (!errors && !warnings))
    )
  };

  _isMeetCustomerLimit = () => {
    // TODO

    // let customersLimit;
    //
    // if (customersLimit = this._maxCustomerLimit()) {
    //   return (customersLimit == this.state.customers.length);
    // }
    // else {
    //   return false;
    // }
  };

  handleCustomerAdd = (event) => {
    event.preventDefault();

    // TODO
    // if (this.state.menu_group_options.length == 0 || this._isMeetCustomerLimit()) {
    //   return;
    // }

    // var params = $.param({
    //   shop_id: this.props.shopId,
    //   from_reservation: true,
    //   reservation_id: this.props.reservation.id,
    //   menu_id: this.state.menu_id,
    //   memo: this.state.memo,
    //   start_time_date_part: this.state.start_time_date_part,
    //   start_time_time_part: this.state.start_time_time_part,
    //   end_time_time_part: this.state.end_time_time_part,
    //   staff_ids: Array.prototype.slice.call(this.state.staff_ids).join(","),
    //   customer_ids: this.state.customers.map(function(c) { return c["value"]; }).join(","),
    // })
    //
    // window.location = `${this.props.customerAddPath}?${params}`
  };

  _customerAddClass = () => {
    // TODO
    // if (this.state.menu_group_options.length == 0) {
    //   return "disabled BTNtarco";
    // }
    // else if (this._isMeetCustomerLimit()) {
    //   return "disabled BTNorange"
    // }
    // else if (!this.props.isEditable) {
    //   return "disabled BTNtarco";
    // }
    // else {
      return "BTNtarco"
    // }
  };

  handleCustomerRemove = (customer_id, event) => {
    // TODO
    // var _this = this;
    // var customers = _.reject(this.state.customers, function(option) {
    //   return option.value == customer_id;
    // });
    //
    // this.setState({customers: customers}, function() {
    //   if (_this.props.memberMode) {
    //     _this._validateReservation()
    //   }
    //   else {
    //     _this._retrieveAvailableMenus()
    //   }
    // })
  };

  start_at = (reservation_form_values = null) => {
    const {
      start_time_date_part,
      start_time_time_part,
    } = (reservation_form_values || this.reservation_form_values);

    if (!start_time_date_part || !start_time_time_part) {
      return;
    }

    return moment.tz(`${start_time_date_part} ${start_time_time_part}`, "YYYY-MM-DD HH:mm", this.props.timezone)
  }

  end_at = (reservation_form_values = null) => {
    const {
      menu_staffs_list,
    } = (reservation_form_values || this.reservation_form_values);

    const start_at = this.start_at(reservation_form_values);

    if (!start_at || !_.filter(menu_staffs_list, (menu) => !!menu.menu_id).length) {
      return;
    }

    const total_required_time = menu_staffs_list.reduce((sum, menu) => sum + Number(menu.menu_required_time || 0), 0)
    return start_at.add(total_required_time, "minutes")
  }
}

export default ManagementReservationForm;
