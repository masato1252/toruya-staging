"use strict";

UI.define("Customers.Filter.QuerySider", function() {
  var CustomersFilterQuerySider = React.createClass({
    getInitialState: function() {
      this.emailTypes = [
        { label: this.props.homeLabel, value: "home" },
        { label: this.props.mobileLabel, value: "mobile" },
        { label: this.props.workLabel, value: "work" }
      ]

      this.initialStates = {
        savedFilterOptions: this.props.savedFilterOptions,
        current_saved_filter_id: "",
        filterCategoryDisplaying: {},
        group_ids: [],
        livingPlaceInside: true,
        states: [],
        state: "",
        has_email: "",
        email_types: [],
        birthdayQueryType: "on",
        custom_id: "",
        custom_ids: [],
        from_dob_year: "",
        from_dob_month: "",
        from_dob_day: "",
        to_dob_year: "",
        to_dob_month: "",
        to_dob_day: "",
        hasReservation: true,
        reservationDateQueryType: "on",
        from_reservation_year: "",
        from_reservation_month: "",
        from_reservation_day: "",
        to_reservation_year: "",
        to_reservation_month: "",
        to_reservation_day: "",
        menu_id: "",
        menu_ids: [],
        staff_id: "",
        staff_ids: [],
        reservation_with_warnings: "",
        reservation_states: []
      }

      return this.initialStates;
    },

    componentDidMount: function() {
      this.applySelect2();
    },

    reset: function() {
      this.setState(_.omit(this.getInitialState(), "savedFilterOptions"));
      this.props.updateFilter("filter_name", "");
      this.props.updateFilter("current_saved_filter_id", "");
    },

    applySelect2: function() {
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
    },

    toggleCategoryDisplay: function(category_type) {
      if (this.state.filterCategoryDisplaying[category_type]) {
        this.state.filterCategoryDisplaying[category_type] = false;
      }
      else {
        this.state.filterCategoryDisplaying[category_type] = true;
      }

      this.setState({filterCategoryDisplaying: this.state.filterCategoryDisplaying});
    },

    onCheckboxChange: function(event) {
      let newValues = this.state[event.target.dataset.name];

      if (_.contains(newValues, event.target.dataset.value)) {
        newValues = _.reject(newValues, function(value) {
           return value === event.target.dataset.value
        })
      }
      else {
        newValues.push(event.target.dataset.value);
      }

      this.setState({[event.target.dataset.name]: newValues})
    },

    onDataChange: function(event) {
      let stateName = event.target.dataset.name;
      let stateValue = event.target.dataset.value || event.target.value;

      this.setState({[stateName]: stateValue});
    },

    onSavedFilterChange: function(event) {
      const _this = this;
      let stateName = event.target.dataset.name;
      let stateValue = event.target.value;

      this.setState({[stateName]: stateValue});
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
    },

    updateFilterOption: function(query, queryCustomers=true) {
      this.setState($.extend({}, this.getInitialState(), query), function() {
        if (queryCustomers) {
          this.submitFilterForm()
        }
      }.bind(this));
      this.props.updateFilter("filter_name", query["current_saved_filter_name"]);
      this.props.updateFilter("current_saved_filter_id", query["current_saved_filter_id"]);
      this.props.updateFilter("current_saved_filter_name", query["current_saved_filter_name"]);
    },

    onRemoveItem: function(event) {
      event.preventDefault();

      let newValues = this.state[event.target.dataset.name];

      if (_.contains(newValues, event.target.dataset.value)) {
        newValues = _.reject(newValues, function(value) {
           return value === event.target.dataset.value
        })
      }

      this.setState({[event.target.dataset.name]: newValues})
    },

    onAddItem: function(event) {
      event.preventDefault();

      let newValues = this.state[event.target.dataset.name];
      let newValue = this.state[event.target.dataset.targetName]
      if (!newValue) { return; }

      if (_.contains(newValues, newValue)) { return; }

      newValues.push(this.state[event.target.dataset.targetName]);

      this.setState({
        [event.target.dataset.name]: newValues,
        [event.target.dataset.targetName]: ""
      });
    },

    submitFilterForm: function() {
      event.preventDefault();
      if (!this.isQueryConditionLegal()) { return; }

      var _this = this;
      var valuesToSubmit = $(this.filterForm).serialize();
      _this.props.startProcessing();

      $.ajax({
        type: "POST",
        url: _this.props.filterPath, //sumbits it to the given url of the form
        data: valuesToSubmit,
        dataType: "JSON"
      }).success(function(result) {
        _this.props.updateCustomers(result["customers"]);
      }).always(function() {
      });
    },

    renderCheckboxOptions: function(options, stateName) {
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
    },

    renderMultipleInputs: function(items, collection_name) {
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
    },

    renderMultipleSelectInputs: function(items, collection_name, mappingOptions) {
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
    },

    renderToggleIcon: function(category_type) {
      if (this.state.filterCategoryDisplaying[category_type]) {
        return <i className="fa fa-minus-square-o" aria-hidden="true"></i>
      }
      else {
        return <i className="fa fa-plus-square-o" aria-hidden="true"></i>
      }
    },

    isQueryConditionLegal: function() {
      return (
        _.uniq([!this.state.from_dob_year, !this.state.from_dob_month, !this.state.from_dob_day]).length === 1 &&
        _.uniq([!this.state.to_dob_year, !this.state.to_dob_month, !this.state.to_dob_day]).length === 1 &&
        _.uniq([!this.state.from_reservation_year, !this.state.from_reservation_month, !this.state.from_reservation_day]).length === 1 &&
        _.uniq([!this.state.to_reservation_year, !this.state.to_reservation_month, !this.state.to_reservation_day]).length === 1
      )
    },

    render: function() {
      return(
        <div id="searchKeys" className="sidel">
          <div id="tabs" className="tabs">
            <a href="search-reservation_result.html"><i className="fa fa-calendar" aria-hidden="true"></i></a>
            <a href="search-customer_result.html" className="here"><i className="fa fa-users" aria-hidden="true"></i></a>
          </div>

          <div id="filterKeys" className="tabBody">
            <div className="filterKey">
              <UI.Select
                includeBlank="true"
                blankOption="Select A Filter"
                options={this.state.savedFilterOptions}
                data-name="current_saved_filter_id"
                value={this.state.current_saved_filter_id}
                onChange={this.onSavedFilterChange}
                />
            </div>
            <h2>{this.props.customerInfoTitle}</h2>
            <div className="filterKey">
              <h3 onClick={this.toggleCategoryDisplay.bind(this, "group_ids")} >
                {this.renderToggleIcon("group_ids")}
                {this.props.customerGroupTitle}
              </h3>
              {
                this.state.filterCategoryDisplaying["group_ids"] ? (
                  <dl className="groups">
                    <dt>Select Groups</dt>
                    <dd>
                      <ul>
                        {this.renderCheckboxOptions(this.props.contactGroupOptions, "group_ids")}
                      </ul>
                    </dd>
                  </dl>
                ) : null
              }
            </div>
            <div className="filterKey">
              <h3 onClick={this.toggleCategoryDisplay.bind(this, "living_place")} >
                {this.renderToggleIcon("living_place")}
                {this.props.customerLivingPlaceTitle}
              </h3>
              {
                this.state.filterCategoryDisplaying["living_place"] ? (
                  <div>
                    <dl className="filterFor">
                      <dd>
                        Living
                        <UI.Select
                          options={this.props.livingPlaceQueryTypeOptions}
                          data-name="livingPlaceInside"
                          value={this.state.livingPlaceInside}
                          onChange={this.onDataChange}
                          />
                      </dd>
                    </dl>
                    <dl className="state">
                      <dt>{this.props.customerLivingPlaceState}</dt>
                      <dd>
                        <ul>
                          {this.renderMultipleInputs(this.state.states, "states")}
                          <li>
                            <UI.Select
                              includeBlank="true"
                              blankOption={this.props.selectRegionLabel}
                              options={this.props.regions}
                              data-name="state"
                              value={this.state.state}
                              onChange={this.onDataChange}
                              />
                            <a
                              href="#"
                              className="BTNyellow"
                              onClick={this.onAddItem}
                              data-target-name="state"
                              data-name="states"
                              >
                              <i
                                className="fa fa-plus"
                                aria-hidden="true"
                                data-target-name="state"
                                data-name="states" >
                              </i>
                            </a>
                          </li>
                        </ul>
                      </dd>
                    </dl>
                  </div>
                ) : null
              }
            </div>
            <div className="filterKey">
              <h3 onClick={this.toggleCategoryDisplay.bind(this, "has_email")} >
                {this.renderToggleIcon("has_email")}
                {this.props.customerEmailTitle}：
              </h3>
              {
                this.state.filterCategoryDisplaying["has_email"] ? (
                  <div>
                    <dl>
                      <dt>{this.props.customerEmailTypes}</dt>
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
                          <dt>has witch email?</dt>
                          <dd>
                            <ul>
                              {this.renderCheckboxOptions(this.emailTypes, "email_types")}
                            </ul>
                          </dd>
                        </dl>
                      ) : null
                    }
                  </div>
                ) : null
              }
            </div>
            <div className="filterKey">
              <h3 onClick={this.toggleCategoryDisplay.bind(this, "birthday")} >
                {this.renderToggleIcon("birthday")}
                {this.props.customerBirthdayTitle}
              </h3>
              {
                this.state.filterCategoryDisplaying["birthday"] ? (
                  <div>
                    <dl className="filterFor">
                      <dd>
                        Born
                        <UI.Select
                          options={this.props.dateQueryOptions}
                          data-name="birthdayQueryType"
                          value={this.state.birthdayQueryType}
                          onChange={this.onDataChange}
                          />
                      </dd>
                    </dl>
                    <dl className="date">
                      <dd>
                        <ul>
                          <li>
                            {
                              this.state.birthdayQueryType === "between" ? (
                                "From"
                              ) : null
                            }
                            <UI.Select
                              includeBlank="true"
                              blankOption={this.props.selectYearLabel}
                              options={this.props.yearOptions}
                              data-name="from_dob_year"
                              value={this.state.from_dob_year}
                              onChange={this.onDataChange}
                              />
                            /&nbsp;
                            <UI.Select
                              includeBlank="true"
                              blankOption={this.props.selectMonthLabel}
                              options={this.props.monthOptions}
                              data-name="from_dob_month"
                              value={this.state.from_dob_month}
                              onChange={this.onDataChange}
                              />
                            /&nbsp;
                            <UI.Select
                              includeBlank="true"
                              blankOption={this.props.selectDayLabel}
                              options={this.props.dayOptions}
                              data-name="from_dob_day"
                              value={this.state.from_dob_day}
                              onChange={this.onDataChange}
                              />
                          </li>
                          {
                            this.state.birthdayQueryType === "between" ? (
                              <li>
                                To
                                <UI.Select
                                  includeBlank="true"
                                  blankOption={this.props.selectYearLabel}
                                  options={this.props.yearOptions}
                                  data-name="to_dob_year"
                                  value={this.state.to_dob_year}
                                  onChange={this.onDataChange}
                                  />
                                /&nbsp;
                                <UI.Select
                                  includeBlank="true"
                                  blankOption={this.props.selectMonthLabel}
                                  options={this.props.monthOptions}
                                  data-name="to_dob_month"
                                  value={this.state.to_dob_month}
                                  onChange={this.onDataChange}
                                  />
                                /&nbsp;
                                <UI.Select
                                  includeBlank="true"
                                  blankOption={this.props.selectDayLabel}
                                  options={this.props.dayOptions}
                                  data-name="to_dob_day"
                                  value={this.state.to_dob_day}
                                  onChange={this.onDataChange}
                                  />
                              </li>
                            ) : null
                          }
                        </ul>
                      </dd>
                    </dl>
                  </div>
                ) : null
              }
            </div>
            <div className="filterKey">
              <h3 onClick={this.toggleCategoryDisplay.bind(this, "custom_ids")} >
                {this.renderToggleIcon("custom_ids")}
                {this.props.customerIdTitle}：
              </h3>
              {
                this.state.filterCategoryDisplaying["custom_ids"] ? (
                  <dl className="customerID">
                    <dd>
                      <ul>
                        {this.renderMultipleInputs(this.state.custom_ids, "custom_ids")}
                        <li>
                          <input
                            type="text"
                            placeholder="letter or number"
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
                      </ul>
                    </dd>
                  </dl>
                ) : null
              }
            </div>
            <h2>{this.props.customerReservationRecordsTitle}：</h2>
            <div className="filterKey">
              <h3 onClick={this.toggleCategoryDisplay.bind(this, "reservation")} >
                {this.renderToggleIcon("reservation")}
                {this.props.customerReservationDateTitle}：
              </h3>
              {
                this.state.filterCategoryDisplaying["reservation"] ? (
                  <div>
                    <dl className="filterFor">
                      <dd>
                        <UI.Select
                          options={this.props.yesNoOptions}
                          data-name="hasReservation"
                          value={this.state.hasReservation}
                          onChange={this.onDataChange}
                          />
                        reservations
                        <UI.Select
                          options={this.props.dateQueryOptions}
                          data-name="reservationDateQueryType"
                          value={this.state.reservationDateQueryType}
                          onChange={this.onDataChange}
                          />
                      </dd>
                    </dl>
                    <dl className="date">
                      <dd>
                        <ul>
                          <li>
                            {
                              this.state.reservationDateQueryType === "between" ? (
                                "From"
                              ) : null
                            }
                            <UI.Select
                              includeBlank="true"
                              blankOption={this.props.selectYearLabel}
                              options={this.props.yearOptions}
                              data-name="from_reservation_year"
                              value={this.state.from_reservation_year}
                              onChange={this.onDataChange}
                              />
                            /&nbsp;
                            <UI.Select
                              includeBlank="true"
                              blankOption={this.props.selectMonthLabel}
                              options={this.props.monthOptions}
                              data-name="from_reservation_month"
                              value={this.state.from_reservation_month}
                              onChange={this.onDataChange}
                              />
                            /&nbsp;
                            <UI.Select
                              includeBlank="true"
                              blankOption={this.props.selectDayLabel}
                              options={this.props.dayOptions}
                              data-name="from_reservation_day"
                              value={this.state.from_reservation_day}
                              onChange={this.onDataChange}
                              />
                          </li>
                          {
                            this.state.reservationDateQueryType === "between" ? (
                              <li>
                                To
                                <UI.Select
                                  includeBlank="true"
                                  blankOption={this.props.selectYearLabel}
                                  options={this.props.yearOptions}
                                  data-name="to_reservation_year"
                                  value={this.state.to_reservation_year}
                                  onChange={this.onDataChange}
                                  />
                                /&nbsp;
                                <UI.Select
                                  includeBlank="true"
                                  blankOption={this.props.selectMonthLabel}
                                  options={this.props.monthOptions}
                                  data-name="to_reservation_month"
                                  value={this.state.to_reservation_month}
                                  onChange={this.onDataChange}
                                  />
                                /&nbsp;
                                <UI.Select
                                  includeBlank="true"
                                  blankOption={this.props.selectDayLabel}
                                  options={this.props.dayOptions}
                                  data-name="to_reservation_day"
                                  value={this.state.to_reservation_day}
                                  onChange={this.onDataChange}
                                  />
                              </li>
                            ) : null
                          }
                        </ul>
                      </dd>
                    </dl>
                  </div>
                ) : null
              }
            </div>

            <div className={
                (this.state.hasReservation === "true" || this.state.hasReservation === true) && this.state.from_reservation_year && this.state.from_reservation_month && this.state.from_reservation_day ? null : "display-hidden"}>
              <div className="filterKey">
                <h3 onClick={this.toggleCategoryDisplay.bind(this, "menu_ids")} >
                  {this.renderToggleIcon("menu_ids")}
                  {this.props.customerReservationMenuTitle}<span>({this.props.customerReservationMultipleChoices})</span>
                </h3>
                <dl className={this.state.filterCategoryDisplaying["menu_ids"] ? null : "display-hidden"}>
                  <dt>Select Menu：</dt>
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
                <h3 onClick={this.toggleCategoryDisplay.bind(this, "staff_ids")} >
                  {this.renderToggleIcon("staff_ids")}
                  {this.props.customerReservationStaffTitle}<span>({this.props.customerReservationMultipleChoices})</span>
                </h3>
                {
                  this.state.filterCategoryDisplaying["staff_ids"] ? (
                    <dl>
                      <dt>Select Staff：</dt>
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
                  ) : null
                }
              </div>
              <div className="filterKey">
                <h3 onClick={this.toggleCategoryDisplay.bind(this, "reservation_with_warnings")} >
                  {this.renderToggleIcon("reservation_with_warnings")}
                  {this.props.customerReservationErrorTitle}：
                </h3>
                {
                  this.state.filterCategoryDisplaying["reservation_with_warnings"] ? (
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
                  ) : null
                }
              </div>
              <div className="filterKey">
                <h3 onClick={this.toggleCategoryDisplay.bind(this, "reservationBeforeCheckedInStates")} >
                  {this.renderToggleIcon("reservationBeforeCheckedInStates")}
                  {this.props.customerReservationStatusTitle}：
                </h3>
                {
                  this.state.filterCategoryDisplaying["reservationBeforeCheckedInStates"] ? (
                    <dl>
                      <dt>{this.props.customerReservationStatusInfo}</dt>
                      <dd>
                        <ul>
                          {this.renderCheckboxOptions(this.props.reservationBeforeCheckedInStateOptions, "reservation_states")}
                        </ul>
                      </dd>
                    </dl>
                  ) : null
                }
              </div>
              <div className="filterKey">
                <h3 onClick={this.toggleCategoryDisplay.bind(this, "reservationAfterCheckedInStates")} >
                  {this.renderToggleIcon("reservationAfterCheckedInStates")}
                  {this.props.customerCheckInStatusTitle}：
                </h3>
                {
                  this.state.filterCategoryDisplaying["reservationAfterCheckedInStates"] ? (
                    <dl>
                      <dt>{this.props.customerCheckInStatusInfo}</dt>
                      <dd>
                        <ul>
                          {this.renderCheckboxOptions(this.props.reservationAfterCheckedInStateOptions, "reservation_states")}
                        </ul>
                      </dd>
                    </dl>
                  ) : null
                }
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
                this.state.current_saved_filter_id ? (
                  <input name="id" type="hidden" value={this.state.current_saved_filter_id} />
                ) : null
              }
              <input name="group_ids" type="hidden" value={this.state.group_ids.join(",")} />
              { this.state.has_email ? <input name="has_email" type="hidden" value={this.state.has_email} /> : null }
              <input name="email_types" type="hidden" value={this.state.email_types.join(",")} />
              <input name="living_place[inside]" type="hidden" value={this.state.livingPlaceInside} />
              {
                this.state.states.join(",") ? (
                  <input name="living_place[states]" type="hidden" value={this.state.states.join(",")} />
                ) : null
              }
              <input name="custom_ids" type="hidden" value={this.state.custom_ids.join(",")} />
              <input name="birthday[query_type]" type="hidden" value={this.state.birthdayQueryType} />
              {
                this.state.from_dob_year && this.state.from_dob_month && this.state.from_dob_day ? (
                  <input
                     name="birthday[start_date]"
                     type="hidden"
                     value={`${this.state.from_dob_year}-${this.state.from_dob_month}-${this.state.from_dob_day}`} />
                 ) : null
              }
              {
                this.state.to_dob_year && this.state.to_dob_month && this.state.to_dob_day ? (
                  <input
                     name="birthday[end_date]"
                     type="hidden"
                     value={`${this.state.to_dob_year}-${this.state.to_dob_month}-${this.state.to_dob_day}`} />
                ) : null
              }
              <input name="reservation[has_reservation]" type="hidden" value={this.state.hasReservation} />
              <input name="reservation[query_type]" type="hidden" value={this.state.reservationDateQueryType} />
              {
                this.state.reservation_with_warnings ? (
                  <input name="reservation[with_warnings]" type="hidden" value={this.state.reservation_with_warnings} />
                ) : null
              }

              {
                this.state.from_reservation_year && this.state.from_reservation_month && this.state.from_reservation_day ? (
                  <input
                     name="reservation[start_date]"
                     type="hidden"
                     value={`${this.state.from_reservation_year}-${this.state.from_reservation_month}-${this.state.from_reservation_day}`} />
                ) : null
              }
              {
                this.state.to_reservation_year && this.state.to_reservation_month && this.state.to_reservation_day ? (
                  <input
                    name="reservation[end_date]"
                    type="hidden"
                    value={`${this.state.to_reservation_year}-${this.state.to_reservation_month}-${this.state.to_reservation_day}`} />
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
  });

  return CustomersFilterQuerySider;
});
