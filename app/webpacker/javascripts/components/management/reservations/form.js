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

  onSubmit = () => {
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

          return (
            <form
              action={this.props.path.save}
              id="save-reservation-form"
              onSubmit={handleSubmit}
              acceptCharset="UTF-8"
              method="post">
              <input name="utf8" type="hidden" value="✓" />
              <input type="hidden" name="authenticity_token" value={this.props.form_authenticity_token} />
              <div id="resNew" className="contents">
                <div id="resInfo" className="contBody">
                  {this.renderReservationDateTime()}
                </div>
              </div>
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
}

export default ManagementReservationForm;
