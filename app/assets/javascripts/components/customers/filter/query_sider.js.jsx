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
        reservationDateQueryType: "on",
        hasReservation: "true",
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
        reservation_with_warning: "",
        reservation_states: []
      }

      return this.initialStates;
    },

    componentDidMount: function() {
      this.applySelect2();
    },

    reset: function() {
      this.setState(this.getInitialState());
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

      this.setState(this.state.filterCategoryDisplaying);
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

      if (_.contains(newValues, newValue)) { return; }

      newValues.push(this.state[event.target.dataset.targetName]);

      this.setState({
        [event.target.dataset.name]: newValues,
        [event.target.dataset.targetName]: ""
      });
    },

    submitFilterForm: function() {
      event.preventDefault();
      var _this = this;
      var valuesToSubmit = $(this.filterForm).serialize();

      $.ajax({
        type: "POST",
        url: _this.props.filterPath, //sumbits it to the given url of the form
        data: valuesToSubmit,
        dataType: "JSON"
      }).success(function(result) {
        // _this.props.handleCreatedCustomer(result["customer"]);
        _this.props.updateCustomers(result["customers"]);
        // _this.props.forceStopProcessing();
      }).always(function() {
        // _this.props.forceStopProcessing();
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

    render: function() {
      return(
        <div id="searchKeys" className="sidel">
          <div id="tabs" className="tabs">
            <a href="search-reservation_result.html"><i className="fa fa-calendar" aria-hidden="true"></i></a>
            <a href="search-customer_result.html" className="here"><i className="fa fa-users" aria-hidden="true"></i></a>
          </div>

          <div id="filterKeys" className="tabBody">
            <h2>Customer Info</h2>
            <div className="filterKey">
              <h3 onClick={this.toggleCategoryDisplay.bind(this, "customer_group")} >
                {this.renderToggleIcon("customer_group")}
                Customer Group
              </h3>
              {
                this.state.filterCategoryDisplaying["customer_group"] ? (
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
                Living Place：居住地
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
                      <dt>State：都道府県</dt>
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
              <h3 onClick={this.toggleCategoryDisplay.bind(this, "email")} >
                {this.renderToggleIcon("email")}
                Email：
              </h3>
              {
                this.state.filterCategoryDisplaying["email"] ? (
                  <div>
                    <dl>
                      <dt>has email address?</dt>
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
                            <label htmlFor="hasEmail">YES：有り</label>
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
                            <label htmlFor="hasNOemail">NO：無し</label>
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
                Date of Birth：生年月日
              </h3>
              {
                this.state.filterCategoryDisplaying["birthday"] ? (
                  <div>
                    <dl class="filterFor">
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
              <h3 onClick={this.toggleCategoryDisplay.bind(this, "customer_id")} >
                {this.renderToggleIcon("customer_id")}
                Customer ID：
              </h3>
              {
                this.state.filterCategoryDisplaying["customer_id"] ? (
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
                            className="BTNyellow"
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
            <h2>Reservation Records：</h2>
            <div className="filterKey">
              <h3 onClick={this.toggleCategoryDisplay.bind(this, "reservationDate")} >
                {this.renderToggleIcon("reservationDate")}
                Date：
              </h3>
              {
                this.state.filterCategoryDisplaying["reservationDate"] ? (
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
              {
                this.state.hasReservation === "true" && this.state.from_reservation_year && this.state.from_reservation_month && this.state.from_reservation_day ? (
            <div>
              <div className="filterKey">
                <h3 onClick={this.toggleCategoryDisplay.bind(this, "reservationMenu")} >
                  {this.renderToggleIcon("reservationMenu")}
                  Menu<span>(multiple choice)</span>
                </h3>
                {
                  this.state.filterCategoryDisplaying["reservationMenu"] ? (
                    <dl>
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
                              className="BTNyellow"
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
                  ) : null
                }
              </div>
              <div className="filterKey">
                <h3 onClick={this.toggleCategoryDisplay.bind(this, "reservationStaff")} >
                  {this.renderToggleIcon("reservationStaff")}
                  Staff<span>(multiple choice)</span>
                </h3>
                {
                  this.state.filterCategoryDisplaying["reservationMenu"] ? (
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
                              className="BTNyellow"
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
                <h3 onClick={this.toggleCategoryDisplay.bind(this, "reservationWithWarning")} >
                  {this.renderToggleIcon("reservationWithWarning")}
                  Error：
                </h3>
                {
                  this.state.filterCategoryDisplaying["reservationWithWarning"] ? (
                  <dl>
                    <dt>has errors?</dt>
                    <dd>
                      <ul>
                        <li>
                          <input
                            type="radio"
                            id="hasANerror"
                            data-name="reservation_with_warning"
                            data-value="true"
                            checked={this.state.reservation_with_warning === "true"}
                            onChange={this.onDataChange}
                            />
                          <label htmlFor="hasANerror">YES：有り</label>
                        </li>
                        <li>
                          <input
                            type="radio"
                            id="hasNOrror"
                            data-name="reservation_with_warning"
                            data-value="false"
                            checked={this.state.reservation_with_warning === "false"}
                            onChange={this.onDataChange}
                            />
                          <label htmlFor="hasNOemail">NO：無し</label>
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
                  Reservation status：
                </h3>
                {
                  this.state.filterCategoryDisplaying["reservationBeforeCheckedInStates"] ? (
                    <dl>
                      <dt>Select status</dt>
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
                  Check-in status：
                </h3>
                {
                  this.state.filterCategoryDisplaying["reservationAfterCheckedInStates"] ? (
                    <dl>
                      <dt>Select status</dt>
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

                ) : null
              }
          </div>
            <form
              acceptCharset="UTF-8"
              id="filter-form"
              method="post"
              ref={(c) => {this.filterForm = c}}
              >
              <input name="utf8" type="hidden" value="✓" />
              <input name="authenticity_token" type="hidden" value={this.props.formAuthToken} />
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
                this.state.reservation_states.join(",") ? (
                  <input name="reservation[states]" type="hidden" value={this.state.reservation_states.join(",")} />
                ) : null
              }

              <div className="submit">
                <a
                  className="BTNtarco"
                  onClick={this.submitFilterForm}
                  href="#"
                  >Search
                </a>
              </div>
            </form>
        </div>
      );
    }
  });

  return CustomersFilterQuerySider;
});
