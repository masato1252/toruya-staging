"use strict";

import React from "react";
import CommonDatepickerField from "../../shared/datepicker_field.js";
import Select from "../../shared/select.js";

var moment = require('moment-timezone');

class CustomersFilterQuerySider extends React.Component {
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
      group_ids: [],
      rank_ids: [],
      livingPlaceInside: true,
      states: [],
      state: "",
      has_email: "",
      email_types: [],
      birthdayQueryType: "on",
      custom_id: "",
      custom_ids: [],
      start_dob_date: "",
      end_dob_date: "",
      month_of_dob: "",
      hasReservation: true,
      reservationDateQueryType: "on",
      start_reservation_date: "",
      end_reservation_date: "",
      shop_id: "",
      shop_ids: [],
      menu_id: "",
      menu_ids: [],
      staff_id: "",
      staff_ids: [],
      reservation_states: []
    }

    this.state = $.extend({}, this.initialStates)
  };

  componentDidMount() {
    this.applySelect2();
  };

  getInitialState = () => {
    return this.initialStates;
  };

  reset = () => {
    this.setState(_.omit(this.getInitialState(), "savedFilterOptions"));
    this.props.updateFilter("filter_name", "");
    this.props.updateFilter("current_saved_filter_id", "");
    this.props.updateFilter("current_saved_filter_name", "");
    this.props.updateFilter("preset_filter_name", "");
    this.props.updateFilter("printing_status", "");
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

  onDataChange = (event) => {
    let stateName = event.target.dataset.name;
    let stateValue = event.target.dataset.value || event.target.value;

    this.setState({[stateName]: stateValue}, function() {
      if (stateName === "state") {
        this.onAddItem(null, "states", "state")
      }
      else if (stateName === "birthdayQueryType") {
        if (stateValue === "on_month") {
          this.setState({start_dob_date: ""})
        }
        else {
          this.setState({month_of_dob: ""})
        }
      }
    }.bind(this));
  };

  onSavedFilterClick = (event) => {
    const _this = this;
    let stateValue = event.target.dataset.value;

    // Load Filter query to option
    if (!stateValue) {
      this.reset();
      this.props.updateCustomers([]);
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

  onCurrentMonthClick = () => {
    this.updateFilterOption({
      birthdayQueryType: "on_month",
      month_of_dob: moment().format("M"),
      preset_filter_name: this.props.dobInCurrentMonth
    })
  };

  onNextMonthClick = () => {
    let nextMonth = moment().add(1, "M");

    this.updateFilterOption({
      birthdayQueryType: "on_month",
      month_of_dob: nextMonth.format("M"),
      preset_filter_name: this.props.dobInNextMonth
    })
  };

  onCheckoutInAYearClick = () => {
    this.updateFilterOption({
      reservationDateQueryType: "between",
      start_reservation_date: moment().add(-1, "Y").format("YYYY-MM-DD"),
      end_reservation_date: moment().format("YYYY-MM-DD"),
      // reservation_states: ["checked_out"],
      reservationDateQueryType: "between",
      preset_filter_name: this.props.checkoutInAYear
    })
  };

  updateFilterOption = (query, queryCustomers=true) => {
    this.setState($.extend({}, _.omit(this.getInitialState(), "savedFilterOptions"), query), function() {
      if (queryCustomers) {
        this.submitFilterForm()
        this.queryConditions = $(this.filterForm).serialize();
      }
    }.bind(this));
    this.props.updateFilter("filter_name", query["current_saved_filter_name"]);
    this.props.updateFilter("current_saved_filter_id", query["current_saved_filter_id"]);
    this.props.updateFilter("current_saved_filter_name", query["current_saved_filter_name"]);
    this.props.updateFilter("preset_filter_name", query["preset_filter_name"]);
    this.props.updateFilter("printing_status", "");
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

  submitFilterForm = () => {
    event.preventDefault();
    if (!this.isQueryConditionLegal()) { return; }

    var _this = this;

    // It would clean existing saved filter id when query conditions changes, let user save a new one.
    if (_this.queryConditions !== $(this.filterForm).serialize()) {
      this.props.updateFilter("filter_name", "");
      this.props.updateFilter("current_saved_filter_id", "");
      this.props.updateFilter("current_saved_filter_name", "");
    }

    this.queryConditions = $(this.filterForm).serialize();
    _this.props.startProcessing();

    $.ajax({
      type: "POST",
      url: _this.props.filterPath, //sumbits it to the given url of the form
      data: _this.queryConditions,
      dataType: "JSON"
    }).success(function(result) {
      _this.props.updateCustomers(result["customers"]);
    }).always(function() {
    });
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

  renderMultipleInputs = (items, collection_name) => {
    return (
      items.map(function(item) {
        return (
          <li key={item}>
            <input type="text" value={item} readOnly />
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

  isQueryConditionLegal = () => {
    return this.isReservationConditionValid();
  };

  renderBirthdayOptions = () => {
    let birthdayOptionView;

    switch (this.state.birthdayQueryType) {
      case "on_month":
        birthdayOptionView = (
          <ul>
            <li>
              <Select
                includeBlank="true"
                blankOption={this.props.selectMonthLabel}
                options={this.props.monthOptions}
                data-name="month_of_dob"
                value={this.state.month_of_dob}
                onChange={this.onDataChange}
                />
            </li>
          </ul>
        )
        break;
      case "on":
      case "before":
      case "after":
        birthdayOptionView = (
          <ul>
            <li>
              <CommonDatepickerField
                date={this.state.start_dob_date}
                dataName="start_dob_date"
                calendarfieldPrefix="start_dob_date"
                hiddenWeekDate={true}
                handleChange={this.onDataChange}
              />
            </li>
          </ul>
        )

        break;
      case "between":
        birthdayOptionView = (
          <ul>
            <li>
              {this.props.locale == "en" ? (
                <span className="filterForWording">{this.props.fromWording}</span>
              ) : null}
              <CommonDatepickerField
                date={this.state.start_dob_date}
                dataName="start_dob_date"
                calendarfieldPrefix="start_dob_date"
                hiddenWeekDate={true}
                handleChange={this.onDataChange}
              />
              {this.props.locale == "ja" ? (
                <span className="filterForWording">{this.props.fromWording}</span>
              ) : null}
            </li>
            <li>
              {this.props.locale == "en" ? (
                <span className="filterForWording">{this.props.toWording}</span>
              ) : null}
              <CommonDatepickerField
                date={this.state.end_dob_date}
                dataName="end_dob_date"
                calendarfieldPrefix="end_dob_date"
                hiddenWeekDate={true}
                handleChange={this.onDataChange}
              />
              {this.props.locale == "ja" ? (
                <span className="filterForWording">{this.props.toWording}</span>
              ) : null}
            </li>
          </ul>
        )
        break;
    }

    return birthdayOptionView;
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
          <CommonDatepickerField
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
              <CommonDatepickerField
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

  isReservationConditionValid = () => {
    if (this.state.shop_ids.length || this.state.menu_ids.length || this.state.staff_ids.length || this.state.reservation_states.length) {
      return !!this.state.start_reservation_date
    }
    else {
      return true
    }
  };

  render() {
    return(
      <div id="searchKeys" className="sidel">
        <div id="tabs" className="tabs">
          <a href="#" className="here"><i className="fa fa-users" aria-hidden="true"></i></a>
          <a href={this.props.reservationFilterPath}><i className="fa fa-calendar" aria-hidden="true"></i></a>
        </div>

        <div id="filterKeys" className="tabBody">
          <h2>{this.props.savedFilterHeader}</h2>
          <div className="savedFilter">
            {this.renderSavedFilters()}
            {this.props.canManagePresetFilter ? (
              <div>
                <a href="#"
                  className="BTNgray"
                  onClick={this.onCurrentMonthClick}>
                  {this.props.dobInCurrentMonth}
                </a>
                <a href="#"
                  className="BTNgray"
                  onClick={this.onNextMonthClick}>
                  {this.props.dobInNextMonth}
                </a>
                <a href="#"
                  className="BTNgray"
                  onClick={this.onCheckoutInAYearClick}>
                  {this.props.checkoutInAYear}
                </a>
              </div>
            ) : null}
          </div>
          <h2>{this.props.customerConditionsHeader}</h2>
          <div className="filterKey">
            <h3>{this.props.customerGroupTitle}</h3>
            <dl className="groups">
              <dt>{this.props.customerGroupTitle}</dt>
              <dd>
                <ul>
                  {this.renderCheckboxOptions(this.props.contactGroupOptions, "group_ids")}
                </ul>
              </dd>
            </dl>
          </div>
          <div className="filterKey">
            <h3>{this.props.customerLevelTitle}</h3>
            <dl className="groups">
              <dt>{this.props.customerLevelTitle}</dt>
              <dd>
                <ul>
                  {this.renderCheckboxOptions(this.props.rankOptions, "rank_ids")}
                </ul>
              </dd>
            </dl>
          </div>
          <div className="filterKey">
            <h3>{this.props.customerLivingPlaceTitle}</h3>
            <div>
              <dl className="filterFor">
                <dd>
                  <Select
                    options={this.props.livingPlaceQueryTypeOptions}
                    data-name="livingPlaceInside"
                    value={this.state.livingPlaceInside}
                    onChange={this.onDataChange}
                    />に在住
                </dd>
              </dl>
              <dl className="state">
                <dt>{this.props.customerLivingPlaceState}</dt>
                <dd>
                  <ul>
                    {this.renderMultipleInputs(this.state.states, "states")}
                    <li>
                      <Select
                        includeBlank="true"
                        blankOption={this.props.selectRegionLabel}
                        options={this.props.regions}
                        data-name="state"
                        value={this.state.state}
                        onChange={this.onDataChange}
                        />
                    </li>
                  </ul>
                </dd>
              </dl>
            </div>
          </div>
          <div className="filterKey">
            <h3>{this.props.customerEmailTitle}</h3>
            <div>
              <dl>
                <dt>{this.props.customerEmailTitle}</dt>
                <dd>
                  <ul>
                    <li>
                      <input
                        type="radio"
                        id="hasEmail"
                        data-name="has_email"
                        data-value="true"
                        checked={this.state.has_email === "true"}
                        onChange={this.onDataChange}
                        />
                      <label htmlFor="hasEmail">{this.props.yesLabel}</label>
                    </li>
                    <li>
                      <input
                        type="radio"
                        id="hasNOemail"
                        data-name="has_email"
                        data-value="false"
                        checked={this.state.has_email === "false"}
                        onChange={this.onDataChange}
                        />
                      <label htmlFor="hasNOemail">{this.props.noLabel}</label>
                    </li>
                  </ul>
                </dd>
              </dl>
              {
                this.state.has_email === "true" ? (
                  <dl>
                    <dt>{this.props.customerEmailTypes}</dt>
                    <dd>
                      <ul>
                        {this.renderCheckboxOptions(this.emailTypes, "email_types")}
                      </ul>
                    </dd>
                  </dl>
                ) : null
              }
            </div>
          </div>
          <div className="filterKey">
            <h3>{this.props.customerBirthdayTitle}</h3>
            <div>
              <dl className="filterFor">
                <dd>
                  <span className="filterForWording">{this.props.bornWording}</span>
                  <Select
                    options={this.props.dobDateQueryOptions}
                    data-name="birthdayQueryType"
                    value={this.state.birthdayQueryType}
                    onChange={this.onDataChange}
                    />
                </dd>
              </dl>
              <dl className="date">
                <dd>
                  {this.renderBirthdayOptions()}
                </dd>
              </dl>
            </div>
          </div>
          <div className="filterKey">
            <h3>{this.props.customerIdTitle}</h3>
            <dl className="customerID">
              <dd>
                <ul>
                  {this.renderMultipleInputs(this.state.custom_ids, "custom_ids")}
                  <li>
                    <input
                      type="text"
                      placeholder={this.props.customIdPlaceholder}
                      value={this.state.custom_id}
                      data-name="custom_id"
                      onChange={this.onDataChange}
                      />
                    <a
                      href="#"
                      className={`BTNyellow ${this.state.custom_id ? null : "disabled"}`}
                      onClick={this.onAddItem}
                      data-target-name="custom_id"
                      data-name="custom_ids"
                      >
                      <i
                        className="fa fa-plus"
                        aria-hidden="true"
                        data-target-name="custom_id"
                        data-name="custom_ids" >
                      </i>
                    </a>
                  </li>
                  {
                    (this.state.custom_id && !_.contains(this.state.custom_ids, this.state.custom_id)) ?
                      (
                        <li className="warning">
                          {this.props.customIdConfirmWarning}
                        </li>
                      ) : null
                  }
                </ul>
              </dd>
            </dl>
          </div>
          <h2>{this.props.customerReservationConditionsHeader}</h2>
          <div className="filterKey">
            <h3>{this.props.customerReservationDateTitle}</h3>
            <div>
              <dl className="filterFor">
                <dd>
                  {this.props.locale === "ja" ? (
                    <Select
                      options={this.props.reservationDateQueryOptions}
                      data-name="reservationDateQueryType"
                      value={this.state.reservationDateQueryType}
                      onChange={this.onDataChange}
                    />
                  ) : (
                    <Select
                      options={this.props.yesNoOptions}
                      data-name="hasReservation"
                      value={this.state.hasReservation}
                      onChange={this.onDataChange}
                      />
                  )}
                  <span className="filterForReservationWording">{this.props.reservationsWording}</span>
                  {this.props.locale === "ja" ? (
                    <Select
                      options={this.props.yesNoOptions}
                      data-name="hasReservation"
                      value={this.state.hasReservation}
                      onChange={this.onDataChange}
                      />
                  ) : (
                    <Select
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
                {this.props.customerReservationShopTitle}<span>({this.props.customerReservationMultipleChoices})</span>
              </h3>
              <dl>
                <dt>{this.props.selectShopLabel}</dt>
                <dd>
                  <ul>
                    {this.renderMultipleSelectInputs(this.state.shop_ids, "shop_ids", this.props.shopOptions)}
                    <li>
                      <Select
                        includeBlank="true"
                        blankOption={this.props.selectShopLabel}
                        options={this.props.shopOptions}
                        id="select2"
                        data-name="shop_id"
                        value={this.state.shop_id}
                        onChange={this.onDataChange}
                        />
                      <a
                        href="#"
                        className={`BTNyellow ${this.state.shop_id ? null : "disabled"}`}
                        onClick={this.onAddItem}
                        data-target-name="shop_id"
                        data-name="shop_ids"
                        >
                        <i
                          className="fa fa-plus"
                          aria-hidden="true"
                          data-target-name="shop_id"
                          data-name="shop_ids" >
                        </i>
                      </a>
                    </li>
                    {
                      (this.state.shop_id && !_.contains(this.state.shop_ids, this.state.shop_id)) ?
                        (
                          <li className="warning">
                            {this.props.shopConfirmWarning}
                          </li>
                        ) : null
                    }
                  </ul>
                </dd>
              </dl>
            </div>
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
                      <Select
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
                    {
                      (this.state.menu_id && !_.contains(this.state.menu_ids, this.state.menu_id)) ?
                        (
                          <li className="warning">
                            {this.props.menuConfirmWarning}
                          </li>
                        ) : null
                    }
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
                      <Select
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
                    {
                      (this.state.staff_id && !_.contains(this.state.staff_ids, this.state.staff_id)) ?
                        (
                          <li className="warning">
                            {this.props.staffConfirmWarning}
                          </li>
                        ) : null
                    }
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
              this.state.group_ids.length !== 0 ? (
                <input name="group_ids" type="hidden" value={this.state.group_ids.join(",")} />
              ) : null
            }
            {
              this.state.rank_ids.length !== 0 ? (
                <input name="rank_ids" type="hidden" value={this.state.rank_ids.join(",")} />
              ) : null
            }
            { this.state.has_email ? <input name="has_email" type="hidden" value={this.state.has_email} /> : null }
            {
              this.state.email_types.length !== 0 ? (
                <input name="email_types" type="hidden" value={this.state.email_types.join(",")} />
              ) : null
            }
            {
              this.state.states.join(",") ? (
                <div>
                  <input name="living_place[inside]" type="hidden" value={this.state.livingPlaceInside} />
                  <input name="living_place[states]" type="hidden" value={this.state.states.join(",")} />
                </div>
              ) : null
            }
            {
              this.state.custom_ids.length !== 0 ? (
                <input name="custom_ids" type="hidden" value={this.state.custom_ids.join(",")} />
              ) : null
            }
            {
              this.state.month_of_dob ? (
                <div>
                  <input name="birthday[query_type]" type="hidden" value={this.state.birthdayQueryType} />
                  <input name="birthday[month]" type="hidden" value={this.state.month_of_dob} />
                </div>
              ) : null
            }
            {
              this.state.start_dob_date ? (
                <div>
                  <input name="birthday[query_type]" type="hidden" value={this.state.birthdayQueryType} />
                  <input
                     name="birthday[start_date]"
                     type="hidden"
                     value={this.state.start_dob_date} />
                </div>
               ) : null
            }
            {
              this.state.end_dob_date ? (
                <input
                   name="birthday[end_date]"
                   type="hidden"
                   value={this.state.end_dob_date} />
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
              this.state.shop_ids.join(",") ? (
                <input name="reservation[shop_ids]" type="hidden" value={this.state.shop_ids.join(",")} />
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

export default CustomersFilterQuerySider;
