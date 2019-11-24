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
import MultipleMenuInput from "./multiple_menu_input.js"
import ReservationCustomersList from "./customers_list.js"
import { displayErrors } from "./helpers.js"
import WorkingSchedulesModal from "../schedules/working_schedules_modal.js"
import StaffStatesModal from "./staff_states_modal.js"
import ProcessingBar from "../../shared/processing_bar.js"

class ManagementReservationForm extends React.Component {
  constructor(props) {
    super(props);
    this.debounceValidateReservation = _.debounce(this.validateReservation, 200, true)

    this.calculator = createChangesDecorator(
      {
        field: /end_time_date_part|end_time_time_part|menu_staffs_list/,
        updates: async (value, name, allValues) => {
          await this.debounceValidateReservation(allValues.reservation_form)
          return {};
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
      },
      {
        field: /menu_staffs_list/,
        updates: async (value, name, allValues) => {
          const {
            menu_staffs_list,
            staff_states,
            by_staff_id,
          } = allValues.reservation_form;

          const {
            existing_staff_states,
            reservation_staff_states: {
              pending_state,
              accepted_state,
            }
          } = this.props.reservation_properties;

          const new_staff_states = this._all_staff_ids(allValues.reservation_form).map((staff_id) => {
            let state;
            let existing_staff_state = staff_states.find(staff_state => String(staff_state.staff_id) === String(staff_id))
            existing_staff_state = existing_staff_state || existing_staff_states.find(staff_state => String(staff_state.staff_id) === String(staff_id))

            if (existing_staff_state) {
              state = existing_staff_state.state
            }
            else if (String(staff_id) === String(by_staff_id)) {
              state = accepted_state
            }
            else {
              state = pending_state
            }

            return (
              {
                staff_id: staff_id,
                state: state
              }
            )
          })

          return {
            "reservation_form[staff_states]": new_staff_states
          }
        }
      }
    )
  };

  componentDidMount() {
    this.debounceValidateReservation()
  };

  renderReservationState = () => {
    const {
      pending_state,
      accepted_state,
    } = this.props.reservation_properties.reservation_staff_states

    const is_reservation_accepted = this._accepted_staffs_number() === this._all_staff_ids().length
    const reservation_current_staffs_state = is_reservation_accepted ? accepted_state : pending_state
    const reservation_state_wording = is_reservation_accepted ? this.props.i18n.accepted_state : this.props.i18n.pending_state

    return (
      <div
        className={`reservation-state-btn btn ${reservation_current_staffs_state}`}
        onClick={() => $("#staff-states-modal").modal("show")}>
        {reservation_state_wording} ({`${this._accepted_staffs_number()}/${this._all_staff_ids().length}`})
        <i className="fa fa-pencil"></i>

        <FieldArray name="reservation_form[staff_states]">
          {({ fields }) => (
            <div>
              {fields.map((name) => (
                <div key={name}>
                  <Field name={`${name}staff_id`} component="input" type="hidden" />
                  <Field name={`${name}state`} component="input" type="hidden" />
                </div>
              ))}
            </div>
          )}
        </FieldArray>
      </div>
    )
  }

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
      date,
      time,
      no_ending_time_message,
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
            <dt className="subject">{date}</dt>
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
            <dt className="subject">{time}</dt>
            <dd className="input">
              <Field
                name="reservation_form[start_time_time_part]"
                type="time"
                component={Input}
                step="300"
                className={`start-time-input ${this.previousReservationOverlap() ? "field-warning" : ""}`}
                disabled={!is_editable}
              />
              <span className="errors">
                {this.startTimeError()}
              </span>
              <span> 〜 {end_at ? end_at.locale('en').format("HH:mm") : "--:--"}</span>
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
              {this.renderReservationState()}
              <span className="errors">
                {this.displayIntervalOverlap()}
                {this.endTimeError()}
              </span>
              {!end_at && <div className="no-end-time-message">{no_ending_time_message}</div>}
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

    return (
      <div className="formRow res-menus">
        <dl className="form">
          <dt className="subject">{content}</dt>
          <dd className="input">
            <MultipleMenuInput
              collection_name="reservation_form[menu_staffs_list]"
              i18n={this.props.i18n}
              reservation_form={this.reservation_form}
              all_values={this.all_values}
              reservation_properties={this.props.reservation_properties}
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
          <dt className="subject">{memo}</dt>
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

  renderCustomersList = () => {
    return (
      <ReservationCustomersList
        collection_name="reservation_form[customers_list]"
        all_values={this.all_values}
        reservation_properties={this.props.reservation_properties}
        reservation_form={this.reservation_form}
        i18n={this.props.i18n}
        addCustomer={this.addCustomer}
      />
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

          const {
            form_authenticity_token
          } = this.props

          const {
            from_customer_id,
            shop,
            shops,
            staff,
          } = this.props.reservation_properties;

          const {
            start_time_date_part,
            start_time_time_part,
            end_time_time_part,
            reservation_id,
            by_staff_id,
          } = values.reservation_form;

          return (
            <div>
              <ProcessingBar processing={values.reservation_form.processing}  />
              <form
                action={this.props.path.save}
                id="save-reservation-form"
                onSubmit={handleSubmit}
                acceptCharset="UTF-8"
                method="post">
                <input name="utf8" type="hidden" value="✓" />
                <input type="hidden" name="authenticity_token" value={form_authenticity_token} />
                <input type="hidden" name="from_customer_id" value={from_customer_id || ""} />
                <Field name="reservation_form[id]" type="hidden" component="input" />
                <Field name="reservation_form[by_staff_id]" type="hidden" component="input" />
                { reservation_id ? <input name="_method" type="hidden" value="PUT" /> : null }
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
              {staff && (
                <WorkingSchedulesModal
                  remote="true"
                  form_authenticity_token={form_authenticity_token}
                  open={true}
                  staff={staff}
                  shop={shop}
                  shops={shops}
                  start_time_date_part={start_time_date_part}
                  start_time_time_part={start_time_time_part}
                  end_time_time_part={end_time_time_part}
                  custom_schedules_path={this.props.path.working_schedule}
                  callback={this.validateReservation}
                />
              )}
              <StaffStatesModal
                reservation_form={this.reservation_form}
                reservation_form_values={this.reservation_form_values}
                reservation_properties={this.props.reservation_properties}
                i18n={this.props.i18n}
                total_staffs_number={this._all_staff_ids().length}
                accepted_staffs_number={this._accepted_staffs_number()}
              />
            </div>
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
      this.reservation_form.change("reservation_form[customer_max_load_capability]", result["customer_max_load_capability"])
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
          "staff_states",
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
      by_staff_id
    } = this.reservation_form_values;
    return this._all_staff_ids().some((staff_id) => String(staff_id) !== String(by_staff_id));
  };

  _accepted_staffs_number = () => {
    const {
      staff_states,
    } = this.reservation_form_values;

    const {
      accepted_state,
    } = this.props.reservation_properties.reservation_staff_states

    return staff_states.filter(staff_state => staff_state.state === accepted_state).length
  }

  _all_staff_ids = (form_values) => {
    form_values = form_values || this.reservation_form_values;

    return _.uniq(
      _.compact(
        _.flatMap(
          form_values.menu_staffs_list, (menu_mapping) => menu_mapping.staff_ids
        ).map((staff) => staff.staff_id)
      )
    )
  }

  _all_menu_ids = () => {
    return _.uniq(
      _.compact(
        _.flatMap(this.reservation_form_values.menu_staffs_list, (menu_mapping) => menu_mapping.menu_id)
      )
    )
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
