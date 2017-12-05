"use strict";

import React from "react";
import "../../shared/datepicker_field.js";

var moment = require('moment-timezone');

UI.define("Reservations.Filter.QuerySider", function() {
  return class ReservationsFilterQuerySider extends React.Component {
    constructor(props) {
      super(props);

      this.emailTypes = [
        { label: this.props.homeLabel, value: "home" },
        { label: this.props.mobileLabel, value: "mobile" },
        { label: this.props.workLabel, value: "work" }
      ]

      this.initialStates = {
        savedFilterOptions: this.props.savedFilterOptions,
        current_saved_filter_id: "",
        hasReservation: true,
        reservationDateQueryType: "on",
        start_reservation_date: "",
        end_reservation_date: "",
        shop_ids: [],
        menu_id: "",
        menu_ids: [],
        staff_id: "",
        staff_ids: [],
        reservation_with_warnings: "",
        reservation_states: []
      }

      this.state = $.extend({}, this.initialStates)
    };

    componentDidMount() {
      this.applySelect2();
    };

    applySelect2 = () => {
      var _this = this;

      $("#select2").select2({
        theme: "bootstrap",
        "language": {
          "noResults": function() {
            return _this.props.noMenuMessage;
          }
        }
      })
      .on("change", _this.onDataChange);
    };

    getInitialState = () => {
      return this.initialStates;
    };

    reset = () => {
      this.setState(_.omit(this.getInitialState(), "savedFilterOptions"));
      this.props.updateFilter({
        "filter_name": "",
        "current_saved_filter_id": "",
        "current_saved_filter_name": "",
        "preset_filter_name": "",
        "printing_status": ""
      });
    };

    renderSavedFilters = () => {
      return (
        <div>
          {
            this.state.savedFilterOptions.length === 0 ? (
              <p className="no-filter">
                {this.props.emptySavedFilterSentenceOne}
                <br />
                {this.props.emptySavedFilterSentenceTwo}
              </p>
            ) : (
              this.props.canManageSavedFilter ? (
                this.state.savedFilterOptions.map(function(option) {
                  return (
                    <a href="#"
                      key={option.value}
                      className="BTNtarco"
                      data-value={option.value}
                      onClick={this.onSavedFilterClick}>
                      {option.label}
                    </a>
                  )
                }.bind(this))
              ) : null
            )
          }
        </div>
      )
    };

    onDataChange = (event) => {
      let stateName = event.target.dataset.name;
      let stateValue = event.target.dataset.value || event.target.value;

      this.setState({[stateName]: stateValue});
    };

    onCheckboxChange = (event) => {
      let newValues = this.state[event.target.dataset.name].slice();

      if (_.contains(newValues, event.target.dataset.value)) {
        newValues = _.reject(newValues, function(value) {
           return value === event.target.dataset.value
        })
      }
      else {
        newValues.push(event.target.dataset.value);
      }

      this.setState({[event.target.dataset.name]: newValues})
    };

    onAddItem = (event, _collectionName, _valueName) => {
      if (event) { event.preventDefault(); }

      let collectionName = event ? event.target.dataset.name : _collectionName;
      let valueName = event ? event.target.dataset.targetName : _valueName;

      let newValues = this.state[collectionName].slice();
      let newValue = this.state[valueName];
      if (!newValue) { return; }

      if (_.contains(newValues, newValue)) { return; }

      newValues.push(newValue);

      this.setState({
        [collectionName]: newValues,
        [valueName]: ""
      });
    };

    onRemoveItem = (event) => {
      event.preventDefault();

      let newValues = this.state[event.target.dataset.name].slice();

      if (_.contains(newValues, event.target.dataset.value)) {
        newValues = _.reject(newValues, function(value) {
           return value === event.target.dataset.value
        })
      }

      this.setState({[event.target.dataset.name]: newValues})
    };

    updateFilterOption = (query, queryReservations = true) => {
      this.setState($.extend({}, _.omit(this.getInitialState(), "savedFilterOptions"), query), function() {
        if (queryReservations) {
          this.submitFilterForm()
          this.queryConditions = $(this.filterForm).serialize();
        }
      }.bind(this));

      this.props.updateFilter({
        "filter_name": query["current_saved_filter_name"],
        "current_saved_filter_id": query["current_saved_filter_id"],
        "current_saved_filter_name": query["current_saved_filter_name"],
        "preset_filter_name": query["preset_filter_name"],
        "printing_status": ""
      })
    };

    submitFilterForm = () => {
      event.preventDefault();
      if (!this.isQueryConditionLegal()) { return; }

      var _this = this;

      // It would clean existing saved filter id when query conditions changes, let user save a new one.
      if (_this.queryConditions !== $(this.filterForm).serialize()) {
        this.props.updateFilter({"filter_name": "", "current_saved_filter_id": "", "current_saved_filter_name": ""});
      }

      this.queryConditions = $(this.filterForm).serialize();
      this.props.startProcessing();

      $.ajax({
        type: "POST",
        url: _this.props.filterPath, //sumbits it to the given url of the form
        data: _this.queryConditions,
        dataType: "JSON"
      }).success(function(result) {
        _this.props.updateResult(result["reservations"]);
      }).always(function() {
      });
    };

    onSavedFilterClick = (event) => {
      const _this = this;
      let stateValue = event.target.dataset.value;

      // Load Filter query to option
      if (!stateValue) {
        this.reset();
        this.props.updateResult([]);
        return;
      }

      $.ajax({
        type: "GET",
        url: this.props.fetchFilterPath, //sumbits it to the given url of the form
        data: { id: stateValue },
        dataType: "JSON"
      }).success(function(result) {
        _this.updateFilterOption(result);
        // _this.props.forceStopProcessing();
      }).always(function() {
        // _this.props.forceStopProcessing();
      });
    };

    renderReservationDateOptions = () => {
      return (
        <ul>
          <li>
            {
              this.state.reservationDateQueryType === "between" && this.props.locale === "en" ? (
                <span className="filterForWording">{this.props.fromWording}</span>
              ) : null
            }
            <UI.Common.DatepickerField
              date={this.state.start_reservation_date}
              dataName="start_reservation_date"
              calendarfieldPrefix="start_reservation_date"
              hiddenWeekDate={true}
              handleChange={this.onDataChange}
              className={this.isReservationConditionValid() ? "" : "field-error"}
            />
            {
              this.state.reservationDateQueryType === "between" && this.props.locale === "ja" ? (
                <span className="filterForWording">{this.props.fromWording}</span>
              ) : null
            }
          </li>
          {
            this.state.reservationDateQueryType === "between" ? (
              <li>
                {this.props.locale === "en" ? (
                  <span className="filterForWording">{this.props.toWording}</span>
                ) : null}
                <UI.Common.DatepickerField
                  date={this.state.end_reservation_date}
                  dataName="end_reservation_date"
                  calendarfieldPrefix="end_reservation_date"
                  hiddenWeekDate={true}
                  handleChange={this.onDataChange}
                  className={this.isReservationConditionValid() ? "" : "field-error"}
                />
                {this.props.locale === "ja" ? (
                  <span className="filterForWording">{this.props.toWording}</span>
                ) : null}
              </li>
            ) : null
          }
        </ul>
      );
    };

    renderMultipleSelectInputs = (items, collection_name, mappingOptions) => {
      return (
        items.map(function(item) {
          let option = _.find(mappingOptions, function(option) { return option.value == item; }.bind(this))

          return (
            <li key={item}>
              <input type="text" value={option.label} readOnly />
              <a href="#"
                 className="BTNorange"
                 data-name={collection_name}
                 data-value={item}
                 onClick={this.onRemoveItem} >
                 <i
                   className="fa fa-minus"
                   aria-hidden="true"
                   data-name={collection_name}
                   data-value={item}>
                 </i>
              </a>
            </li>
          )
        }.bind(this))
      )
    };

    renderCheckboxOptions = (options, stateName) => {
      return (
        options.map(function(option) {
          return (
            <li key={`${stateName}-${option.value}`}>
              <input
                type="checkbox"
                id={`${stateName}-${option.value}`}
                onChange={this.onCheckboxChange}
                data-name={stateName}
                data-value={option.value}
                value={option.value}
                checked={_.contains(this.state[stateName], `${option.value}`)}
                />
              <label htmlFor={`${stateName}-${option.value}`}>{option.label}</label>
            </li>
          )
        }.bind(this))
      )
    };

    isReservationConditionValid = () => {
      return !!this.state.start_reservation_date
    };

    isQueryConditionLegal = () => {
      return this.isReservationConditionValid() && this.state.shop_ids.length > 0;
    };

    render() {
      return(
        <div id="searchKeys" className="sidel">
          <div id="tabs" className="tabs">
            <a href="#" className="here"><i className="fa fa-users" aria-hidden="true"></i></a>
            <a href="#"><i className="fa fa-calendar" aria-hidden="true"></i></a>
          </div>

          <div id="filterKeys" className="tabBody">
            <h2>{this.props.savedFilterHeader}</h2>
            <div className="savedFilter">
              {this.renderSavedFilters()}
            </div>
            <h2>{this.props.customerReservationConditionsHeader}</h2>

            <div className="filterKey">
            <h3>Shops</h3>
              <dl className="groups">
                <dt>{this.props.customerGroupTitle}</dt>
                <dd>
                  <ul>
                    {this.renderCheckboxOptions(this.props.shopOptions, "shop_ids")}
                  </ul>
                </dd>
              </dl>
            </div>
            <div className="filterKey">
              <h3>{this.props.customerReservationDateTitle}</h3>
              <div>
                <dl className="filterFor">
                  <dd>
                    {this.props.locale === "ja" ? (
                      <UI.Select
                        options={this.props.reservationDateQueryOptions}
                        data-name="reservationDateQueryType"
                        value={this.state.reservationDateQueryType}
                        onChange={this.onDataChange}
                      />
                    ) : (
                      this.props.yesNoOptions[0]["label"]
                    )}
                    <span className="filterForReservationWording">{this.props.reservationsWording}</span>
                    {this.props.locale === "ja" ? (
                      this.props.yesNoOptions[0]["label"]
                    ) : (
                      <UI.Select
                        options={this.props.reservationDateQueryOptions}
                        data-name="reservationDateQueryType"
                        value={this.state.reservationDateQueryType}
                        onChange={this.onDataChange}
                      />
                    )}
                  </dd>
                </dl>
                <dl className="date">
                  <dd>
                    {this.renderReservationDateOptions()}
                  </dd>
                </dl>
              </div>
            </div>

            <div>
              <div className="filterKey">
                <h3>
                  {this.props.customerReservationMenuTitle}<span>({this.props.customerReservationMultipleChoices})</span>
                </h3>
                <dl>
                  <dt>{this.props.selectMenuLabel}</dt>
                  <dd>
                    <ul>
                      {this.renderMultipleSelectInputs(this.state.menu_ids, "menu_ids", this.props.menuOptions)}
                      <li>
                        <UI.Select
                          includeBlank="true"
                          blankOption={this.props.selectMenuLabel}
                          options={this.props.menuGroupOptions}
                          id="select2"
                          data-name="menu_id"
                          value={this.state.menu_id}
                          onChange={this.onDataChange}
                          />
                        <a
                          href="#"
                          className={`BTNyellow ${this.state.menu_id ? null : "disabled"}`}
                          onClick={this.onAddItem}
                          data-target-name="menu_id"
                          data-name="menu_ids"
                          >
                          <i
                            className="fa fa-plus"
                            aria-hidden="true"
                            data-target-name="menu_id"
                            data-name="menu_ids" >
                          </i>
                        </a>
                      </li>
                    </ul>
                  </dd>
                </dl>
              </div>
              <div className="filterKey">
                <h3>
                  {this.props.customerReservationStaffTitle}<span>({this.props.customerReservationMultipleChoices})</span>
                </h3>
                <dl>
                  <dt>{this.props.selectStaffLabel}</dt>
                  <dd>
                    <ul>
                      {this.renderMultipleSelectInputs(this.state.staff_ids, "staff_ids", this.props.staffOptions)}
                      <li>
                        <UI.Select
                          includeBlank="true"
                          blankOption={this.props.selectStaffLabel}
                          options={this.props.staffOptions}
                          data-name="staff_id"
                          value={this.state.staff_id}
                          onChange={this.onDataChange}
                        />
                        <a
                          href="#"
                          className={`BTNyellow ${this.state.staff_id ? null : "disabled"}`}
                          onClick={this.onAddItem}
                          data-target-name="staff_id"
                          data-name="staff_ids"
                          >
                          <i
                            className="fa fa-plus"
                            aria-hidden="true"
                            data-target-name="staff_id"
                            data-name="staff_ids" >
                          </i>
                        </a>
                      </li>
                    </ul>
                  </dd>
                </dl>
              </div>
              <div className="filterKey">
                <h3>{this.props.customerReservationErrorTitle}</h3>
                <dl>
                  <dt>has errors?</dt>
                  <dd>
                    <ul>
                      <li>
                        <input
                          type="radio"
                          id="hasANerror"
                          data-name="reservation_with_warnings"
                          data-value="true"
                          checked={this.state.reservation_with_warnings === "true"}
                          onChange={this.onDataChange}
                          />
                        <label htmlFor="hasANerror">{this.props.yesLabel}</label>
                      </li>
                      <li>
                        <input
                          type="radio"
                          id="hasNOrror"
                          data-name="reservation_with_warnings"
                          data-value="false"
                          checked={this.state.reservation_with_warnings === "false"}
                          onChange={this.onDataChange}
                          />
                        <label htmlFor="hasNOrror">{this.props.noLabel}</label>
                      </li>
                    </ul>
                  </dd>
                </dl>
              </div>
              <div className="filterKey">
                <h3>{this.props.customerReservationStatusTitle}</h3>
                <dl>
                  <dt>{this.props.customerReservationStatusInfo}</dt>
                  <dd>
                    <ul>
                      {this.renderCheckboxOptions(this.props.reservationBeforeCheckedInStateOptions, "reservation_states")}
                    </ul>
                  </dd>
                </dl>
              </div>
              <div className="filterKey">
                <h3>{this.props.customerCheckInStatusTitle}</h3>
                <dl>
                  <dt>{this.props.customerCheckInStatusInfo}</dt>
                  <dd>
                    <ul>
                      {this.renderCheckboxOptions(this.props.reservationAfterCheckedInStateOptions, "reservation_states")}
                    </ul>
                  </dd>
                </dl>
              </div>
            </div>
          </div>
            <form
              acceptCharset="UTF-8"
              id="filter-form"
              method="post"
              ref={(c) => {this.filterForm = c}}
              >
              <input name="utf8" type="hidden" value="✓" />
              <input name="authenticity_token" type="hidden" value={this.props.formAuthToken} />
              {
                this.state.shop_ids.join(",") ? (
                  <input name="reservation[shop_ids]" type="hidden" value={this.state.shop_ids.join(",")} />
                ) : null
              }
              {
                this.state.reservation_with_warnings ? (
                  <input name="reservation[with_warnings]" type="hidden" value={this.state.reservation_with_warnings} />
                ) : null
              }

              {
                this.state.start_reservation_date ? (
                  <div>
                    <input name="reservation[has_reservation]" type="hidden" value={this.state.hasReservation} />
                    <input name="reservation[query_type]" type="hidden" value={this.state.reservationDateQueryType} />
                    <input
                      name="reservation[start_date]"
                      type="hidden"
                      value={this.state.start_reservation_date} />
                  </div>
                ) : null
              }
              {
                this.state.end_reservation_date ? (
                  <input
                    name="reservation[end_date]"
                    type="hidden"
                    value={this.state.end_reservation_date} />
                ) : null
              }
              {
                this.state.menu_ids.join(",") ? (
                  <input name="reservation[menu_ids]" type="hidden" value={this.state.menu_ids.join(",")} />
                ) : null
              }
              {
                this.state.staff_ids.join(",") ? (
                  <input name="reservation[staff_ids]" type="hidden" value={this.state.staff_ids.join(",")} />
                ) : null
              }
              {
                this.state.reservation_states.join(",") ? (
                  <input name="reservation[states]" type="hidden" value={this.state.reservation_states.join(",")} />
                ) : null
              }

              <div className="submit">
                <a
                  className={`BTNtarco ${this.isQueryConditionLegal() ? null : "disabled"}`}
                  onClick={this.submitFilterForm}
                  href="#"
                  >{this.props.searchLabel}
                </a>
              </div>
            </form>

        </div>
     );
   }
  };
});

export default UI.Reservations.Filter.QuerySider;
