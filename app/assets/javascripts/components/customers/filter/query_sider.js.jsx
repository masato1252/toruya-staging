"use strict";

UI.define("Customers.Filter.QuerySider", function() {
  var CustomersFilterQuerySider = React.createClass({
    getInitialState: function() {
      this.emailTypes = [
        { label: this.props.homeLabel, value: "home" },
        { label: this.props.mobileLabel, value: "mobile" },
        { label: this.props.workLabel, value: "work" }
      ]

      return ({
        filterCategoryDisplaying: {},
        group_ids: [],
        email_types: [],
        region: "",
        city: "",
        cities: [],
        custom_id: "",
        custom_ids: [],
        has_email: "",
        from_dob_year: "",
        from_dob_month: "",
        from_dob_day: "",
        to_dob_year: "",
        to_dob_month: "",
        to_dob_day: ""
      });
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

      this.setState({[stateName]: stateValue}, function() {
        if (
          (stateName === "from_dob_year" || stateName === "from_dob_month" || stateName === "from_dob_day") &&
        this.state.from_dob_year && this.state.from_dob_month && this.state.from_dob_day &&
        !this.state.to_dob_year && !this.state.to_dob_month && !this.state.to_dob_day
      ) {
          this.setState({
            to_dob_year: this.state.from_dob_year,
            to_dob_month: this.state.from_dob_month,
            to_dob_day: this.state.from_dob_day
          })
        }
      });
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

    renderContactGroupOptions: function() {
      return (
        this.props.contactGroupOptions.map(function(option) {
          return (
            <li key={`group-${option.value}`}>
              <input
                type="checkbox"
                id={`group-${option.value}`}
                onChange={this.onCheckboxChange}
                data-name="group_ids"
                data-value={option.value}
                value={option.value}
                checked={_.contains(this.state.group_ids, `${option.value}`)}
                />
              <label htmlFor={`group-${option.value}`}>{option.label}</label>
            </li>
          )
        }.bind(this))
      )
    },

    renderEmailTypes: function() {
      return (
        this.emailTypes.map(function(option) {
          return (
            <li key={option.value} >
              <input
                type="checkbox"
                id={`email-${option.value}`}
                onChange={this.onCheckboxChange}
                data-name="email_types"
                data-value={option.value}
                value={option.value}
                checked={_.contains(this.state.email_types, `${option.value}`)}
                />
              <label htmlFor={`email-${option.value}`}>{option.label}</label>
            </li>
          )
        }.bind(this))
      )
    },

    renderCitiesInput: function() {
      return (
        this.state.cities.map(function(city, i) {
          return (
            <li key={`${city}-${i}`}>
              <input type="text" id="city" value={city} readOnly />
              <a href="#"
                 className="BTNorange"
                 data-name="cities"
                 data-value={city}
                 onClick={this.onRemoveItem} >
                 <i
                   className="fa fa-minus"
                   aria-hidden="true"
                   data-name="cities"
                   data-value={city}>
                 </i>
              </a>
            </li>
          )
        }.bind(this))
      )
    },

    renderCustomIdInput: function() {
      return (
        this.state.custom_ids.map(function(custom_id, i) {
          return (
            <li key={`${custom_id}-${i}`}>
              <input type="text" value={custom_id} readOnly />
              <a href="#"
                 className="BTNorange"
                 data-name="custom_ids"
                 data-value={custom_id}
                 onClick={this.onRemoveItem} >
                 <i
                   className="fa fa-minus"
                   aria-hidden="true"
                   data-name="custom_ids"
                   data-value={custom_id}>
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

          <div className="filterFor">
            <select>
              <option value="all">Match all</option>
              <option value="any">Match any</option>
              <option value="no">No Match</option>
            </select>&nbsp;of the following
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
                        {this.renderContactGroupOptions()}
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
                    <dl className="state">
                      <dt>State：都道府県</dt>
                      <dd>
                        <UI.Select
                          includeBlank="true"
                          blankOption={this.props.selectRegionLabel}
                          options={this.props.regions}
                          data-name="region"
                          value={this.state.region}
                          onChange={this.onDataChange}
                          />
                      </dd>
                    </dl>
                    {
                      this.state.region ? (
                        <dl className="city">
                          <dt>City：市区町村</dt>
                          <dd>
                            <ul>
                              {this.renderCitiesInput()}
                              <li>
                                <input
                                  type="text"
                                  placeholder="Type City"
                                  value={this.state.city}
                                  data-name="city"
                                  onChange={this.onDataChange}
                                  />
                                <a
                                  href="#"
                                  className="BTNyellow"
                                  onClick={this.onAddItem}
                                  data-target-name="city"
                                  data-name="cities"
                                  >
                                  <i
                                    className="fa fa-plus"
                                    aria-hidden="true"
                                    data-target-name="city"
                                    data-name="cities" >
                                  </i>
                                </a>
                              </li>
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
                              {this.renderEmailTypes()}
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
                  <dl>
                    <dd>
                      <ul>
                        <li>
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
                        <li>〜
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
                      </ul>
                    </dd>
                  </dl>
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
                        {this.renderCustomIdInput()}
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
              <h3><i className="fa fa-plus-square-o" aria-hidden="true"></i>Reservation：</h3>
              <dl>
                <dt>has reservation?</dt>
                <dd>
                  <ul>
                    <li><input type="radio" name="has_reservation" id="hasRes" /><label htmlFor="hasRes">YES：</label></li>
                    <li><input type="radio" name="has_reservation" id="hasNoRes" /><label htmlFor="hasNoRes">NO：</label></li>
                  </ul>
                </dd>
              </dl>
            </div>
            <div className="filterKey">
              <h3><i className="fa fa-plus-square-o" aria-hidden="true"></i>Date：</h3>
              <dl className="date">
                <dt>Select a Date：</dt>
                <dd>
                  <ul>
                    <li>
                      <UI.Select
                        includeBlank="true"
                        blankOption={this.props.selectYearLabel}
                        options={this.props.yearOptions}
                        />
                      /&nbsp;
                      <UI.Select
                        includeBlank="true"
                        blankOption={this.props.selectMonthLabel}
                        options={this.props.monthOptions}
                        />
                      /&nbsp;
                      <UI.Select
                        includeBlank="true"
                        blankOption={this.props.selectDayLabel}
                        options={this.props.dayOptions}
                        />
                    </li>
                    <li>〜
                      <UI.Select
                        includeBlank="true"
                        blankOption={this.props.selectYearLabel}
                        options={this.props.yearOptions}
                        />
                      /&nbsp;
                      <UI.Select
                        includeBlank="true"
                        blankOption={this.props.selectMonthLabel}
                        options={this.props.monthOptions}
                        />
                      /&nbsp;
                      <UI.Select
                        includeBlank="true"
                        blankOption={this.props.selectDayLabel}
                        options={this.props.dayOptions}
                        />
                    </li>
                  </ul>
                </dd>
              </dl>
            </div>
            <div className="filterKey">
              <h3><i className="fa fa-plus-square-o" aria-hidden="true"></i>Menu<span>(multiple choice)</span></h3>
              <dl>
                <dt>Select Menu：</dt>
                <dd>
                  <ul>
                    <li><input type="text" defaultValue="Menu1" className="selected" /><a href="#" className="BTNorange"><i className="fa fa-minus" aria-hidden="true"></i></a></li>
                    <li><input type="text" placeholder="Select a Menu" /><a href="#" className="BTNyellow"><i className="fa fa-plus" aria-hidden="true"></i></a></li>
                  </ul>
                </dd>
              </dl>
            </div>
            <div className="filterKey">
              <h3><i className="fa fa-plus-square-o" aria-hidden="true"></i>Staff<span>(multiple choice)</span></h3>
              <dl>
                <dt>Select Staff：</dt>
                <dd>
                  <ul>
                    <li><input type="text" defaultValue="Staff 1" className="selected" /><a href="#" className="BTNorange"><i className="fa fa-minus" aria-hidden="true"></i></a></li>
                    <li><input type="text" placeholder="Select a Staff" /><a href="#" className="BTNyellow"><i className="fa fa-plus" aria-hidden="true"></i></a></li>
                  </ul>
                </dd>
              </dl>
            </div>
            <div className="filterKey">
              <h3><i className="fa fa-plus-square-o" aria-hidden="true"></i>Error：</h3>
              <dl>
                <dt>has errors?</dt>
                <dd>
                  <ul>
                    <li><input type="radio" name="has_errors" id="hasANerror" /><label htmlFor="hasANerror">YES：</label></li>
                    <li><input type="radio" name="has_errors" id="hasNOrror" /><label htmlFor="hasNOrror">NO：</label></li>
                  </ul>
                </dd>
              </dl>
            </div>
            <div className="filterKey">
              <h3><i className="fa fa-plus-square-o" aria-hidden="true"></i>Reservation status：</h3>
              <dl>
                <dt>Select status</dt>
                <dd>
                  <ul>
                    <li><input type="radio" name="res_status" id="res_pending" /><label htmlFor="res_pending">pending</label></li>
                    <li><input type="radio" name="res_status" id="res_reserved" /><label htmlFor="res_reserved">reserved</label></li>
                    <li><input type="radio" name="res_status" id="res_cancelled" /><label htmlFor="res_cancelled">cancelled</label></li>
                  </ul>
                </dd>
              </dl>
            </div>
            <div className="filterKey">
              <h3><i className="fa fa-plus-square-o" aria-hidden="true"></i>Check-in status</h3>
              <dl>
                <dt>Select status</dt>
                <dd>
                  <ul>
                    <li><input type="radio" name="checkin_status" id="checked_in" /><label htmlFor="checked_in">checked-in</label></li>
                    <li><input type="radio" name="checkin_status" id="checked_out" /><label htmlFor="checked_out">checked-out</label></li>
                    <li><input type="radio" name="checkin_status" id="no_show" /><label htmlFor="no_show">no-show</label></li>
                  </ul>
                </dd>
              </dl>
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
              <input name="group_ids" type="hidden" value={this.state.group_ids.join(",")} />
              { this.state.has_email ? <input name="has_email" type="hidden" value={this.state.has_email} /> : null }
              <input name="email_types" type="hidden" value={this.state.email_types.join(",")} />
              <input name="region" type="hidden" value={this.state.region} />
              <input name="cities" type="hidden" value={this.state.cities.join(",")} />
              <input name="custom_ids" type="hidden" value={this.state.custom_ids.join(",")} />
              <input
                 name="dob[from]"
                 type="hidden"
                 value={
                   this.state.from_dob_year && this.state.from_dob_month && this.state.from_dob_day ?
                   `${this.state.from_dob_year}-${this.state.from_dob_month}-${this.state.from_dob_day}` : ""
                 } />
              <input
                 name="dob[to]"
                 type="hidden"
                 value={
                   this.state.to_dob_year && this.state.to_dob_month && this.state.to_dob_day ?
                   `${this.state.to_dob_year}-${this.state.to_dob_month}-${this.state.to_dob_day}` : ""
                 } />

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
