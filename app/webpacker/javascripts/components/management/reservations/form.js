"use strict";

import React from "react";
import { Form, Field } from "react-final-form";
import createChangesDecorator from "final-form-calculate";
import moment from "moment-timezone";
import axios from "axios";

import DateFieldAdapter from "../../shared/date_field_adapter";
import { Input } from "../../shared/components";

class ManagementReservationForm extends React.Component {
  static errorGroups() {
    return (
      {
        warnings: ["shop_closed", "interval_too_short"]
      }
    )
  };

  constructor(props) {
    super(props);

    this.calculator = createChangesDecorator(
      {
        field: /start_time_date_part|start_time_time_part|end_time_time_part/,
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
      }
    )
  };

  componentDidMount() {
    this.validateReservation()
  };

  renderReservationDateTime = () => {
    const { start_time_restriction, end_time_restriction } = this.reservation_form_values;
    const { is_editable, shop_name } = this.props.reservation_properties;
    const { valid_time_tip_message } = this.props.i18n;

    return (
      <div>
        <h2>
          <i className="fa fa-calendar-o" aria-hidden="true"></i>
          予約詳細
        </h2>
        <div id="resDateTime" className="formRow">
          <dl className="form" id="resDate">
            <dt>日付</dt>
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
            <dt>時間</dt>
            <dd className="input">
              <Field
                name="reservation_form[start_time_time_part]"
                type="time"
                component={Input}
                step="300"
                className={this.previousReservationOverlap() ? "field-warning" : ""}
                disabled={!is_editable}
              />
              〜
              <Field
                name="reservation_form[end_time_date_part]"
                type="hidden"
                component="input"
              />
              <Field
                name="reservation_form[end_time_time_part]"
                type="time"
                component={Input}
                step="300"
                className={this.nextReservationOverlap() ? "field-warning" : ""}
                disabled={!is_editable}
              />
              <span className="errors">
                {this.isValidReservationTime() ? null : <span className="warning">{valid_time_tip_message}</span>}
                {this.displayErrors(["interval_too_short"])}
              </span>
            </dd>
          </dl>
        </div>
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

  renderFooterBar = () => {
    const {
      delete_reservation,
      delete_confirmation_message,
      confirm_with_warnings,
    } = this.props.i18n;
    const {
      reservation_id,
      from_customer_id,
      from_shop_id,
    } = this.props.reservation_properties;
    const { submitting } = this.reservation_form_values;

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
        decorators={[this.calculator]}
        render={({ handleSubmit, submitting, values, errors, form, pristine }) => {
          this.reservation_form = form;
          this.reservation_form_values = values.reservation_form
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
              { this.props.reservation_properties.reservation_id ?  <input name="_method" type="hidden" value="PUT" /> : null }
              <div id="resNew" className="contents">
                <div id="resInfo" className="contBody">
                  {this.renderReservationDateTime()}
                  {this.renderReservationMemo()}
                </div>
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
        params: _.pick(
          form_values,
          "reservation_id",
          "start_time_date_part",
          "start_time_time_part",
          "end_time_date_part",
          "end_time_time_part",
        ),
        responseType: "json",
        cancelToken: this.validateReservationCall.token
      })

      const result = response.data;
      this.reservation_form.change("reservation_form[start_time_restriction]", result["start_time_restriction"])
      this.reservation_form.change("reservation_form[end_time_restriction]", result["end_time_restriction"])
      this.reservation_form.change("reservation_form[errors]", result["errors"])
      // not enough
      // this.reservation_form.change("reservation_form[menu_min_staffs_number]", result["end_time_restriction"])
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

  displayErrors = (error_reasons) => {
    let error_messages = [];

    error_reasons.forEach((error_reason) => {
      if (this.reservation_form_values.errors && this.reservation_form_values.errors[error_reason]) {
        if (_.intersection([error_reason], ManagementReservationForm.errorGroups().warnings).length != 0) {
          error_messages.push(<span className="warning" key={error_reason}>{this.reservation_form_values.errors[error_reason]}</span>)
        }
        else {
          error_messages.push(<span className="danger" key={error_reason}>{this.reservation_form_values.errors[error_reason]}</span>)
        }
      }
    })

    return _.compact(error_messages);
  };

  dateErrors = () => {
    return this.displayErrors(["shop_closed"]);
  };

  previousReservationOverlap = () => {
    return this.displayErrors(["previous_reservation_interval_overlap"]).length != 0;
  };

  nextReservationOverlap = () => {
    return this.displayErrors(["next_reservation_interval_overlap"]).length != 0;
  };

  isValidReservationTime = () => {
    const {
      start_time_restriction,
      end_time_restriction,
      start_time_date_part,
      start_time_time_part,
      end_time_time_part
    } = this.reservation_form_values;

    if (start_time_restriction && end_time_restriction && start_time_time_part && end_time_time_part) {
      const reservation_start_time = moment(`${start_time_date_part} ${start_time_time_part}`);
      const reservation_end_time = moment(`${start_time_date_part} ${end_time_time_part}`);

      return reservation_start_time  >= moment(`${start_time_date_part} ${start_time_restriction}`) &&
             reservation_end_time <= moment(`${start_time_date_part} ${end_time_restriction}`) &&
             reservation_start_time < reservation_end_time
    }
    else {
      return false;
    }
  };

  otherStaffsResponsibleThisReservation = () => {
    // TODO
    // menu_staffs_list
    // [
    //   {
    //     menu_id: menu_id,
    //     menu_interval_time: 10,
    //     staff_ids: $staff_ids,
    //     work_start_at: $work_start_time,
    //     work_end_at: $work_end_time
    //   }
    // ]
    // const all_staff_ids = _.flatMap(this.reservation_form_values.menu_staffs_list, (menu_mapping) => menu_mapping.staff_ids)
    // return all_staff_ids.some(staff_id => staff_id !== this.props.currentUserStaffId);

    return true;
  };

  _isValidToReserve = () => {
    // TODO
    // let errors = _.intersection(Object.keys(this.state.errors), ReservationForm.errorGroups().errors)
    //
    // return (
    //   this.props.isEditable &&
    //   this.state.start_time_date_part &&
    //   this.state.start_time_time_part &&
    //   this.state.end_time_time_part &&
    //   this.state.menu_id &&
    //   this.state.staff_ids.length &&
    //   (this.state.rough_mode ? errors.length == 0 : (errors.length == 0 && !this._isAnyWarning()))
    // )
    return true;
  };
}

export default ManagementReservationForm;
