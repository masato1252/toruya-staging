//= require "components/shared/customers_list"
//
"use strict";

UI.define("Customers.Dashboard", function() {
  var CustomersDashboard = React.createClass({
    getInitialState: function() {
      return ({
        customers: this.props.customers,
        selected_customer_id: "",
        selectedFilterPatternNumber: "",
        customer: this.props.customer
      });
    },

    handleCustomerSelect: function(customer_id, event) {
      if (this.state.selected_customer_id == customer_id) {
        this.setState({selected_customer_id: "", customer: {}});
      }
      else {
        var selected_customer = _.find(this.state.customers, function(customer){ return customer.id == customer_id; })
        this.setState({selected_customer_id: customer_id, customer: selected_customer});
      }
    },

    handleAddCustomerToReservation: function(event) {
      event.preventDefault();
      window.location = this.props.addReservationPath + window.location.search + "," + this.state.selected_customer_id;
    },

    isCustomerdataValid: function() {
      return this.state.customer.firstName || this.state.customer.lastName || this.state.customer.jpFirstName || this.state.customer.jpLastName
    },

    handleCreateCustomer: function(event) {
      event.preventDefault();

      var _this = this;

      if (this.isCustomerdataValid()) {
        var valuesToSubmit = $("#new_customer_form").serialize();

        $.ajax({
          type: "POST",
          url: this.props.saveCustomerPath, //sumbits it to the given url of the form
          data: valuesToSubmit,
          dataType: "JSON"
        }).success(function(result){
          _this.state.customers.unshift(result["customer"])
          _this.setState({customers: _this.state.customers, customer: {}, selected_customer_id: ""});
        });
      }
    },

    handleDeleteCustomer: function(event) {
      event.preventDefault();

      var _this = this;

      this.setState({customers: _.reject(this.state.customers, function(customer) {
        return customer.id == _this.state.selected_customer_id;
      }), customer: {}, selected_customer_id: ""})

      jQuery.ajax({
        type: "POST",
        url: this.props.deleteCustomerPath,
        data: { _method: "delete", id: this.state.selected_customer_id },
        dataType: "json",
      })
    },

    filterCustomers: function(event) {
      event.preventDefault();
      var _this = this;

      if (this.currentRequest != null) {
        this.currentRequest.abort();
      }

      this.setState({selectedFilterPatternNumber: event.target.value})

      this.currentRequest = jQuery.ajax({
        url: this.props.customersFilterPath,
        data: { pattern_number: event.target.value },
        dataType: "json",
      }).done(
        function(result) {
          _this.setState({customers: result["customers"]});
      }).fail(function(errors){
      }).always(function() {
        _this.setState({Loading: false});
      });
    },

    handleSearch: function(event) {
      if (event.key === 'Enter') {
        console.log('do validate');

        event.preventDefault();
        var _this = this;

        if (this.currentRequest != null) {
          this.currentRequest.abort();
        }

        this.currentRequest = jQuery.ajax({
          url: this.props.customersSearchPath,
          data: { keyword: event.target.value },
          dataType: "json",
        }).done(
          function(result) {
            _this.setState({customers: result["customers"]});
        }).fail(function(errors){
        }).always(function() {
          _this.setState({Loading: false});
        });
      }
    },

    handleCustomerDataChange: function(event) {
      event.preventDefault();
      var newCustomer = this.state.customer;

      newCustomer[event.target.dataset.name] = event.target.value;

      this.setState({customer: newCustomer});
    },

    render: function() {
      return(
        <div>
          <div id="customer" className="contents">
            <div id="resultList" className="sidel">
              <ul>
                <li><i className="customer-level-symbol normal" /><span className="wording">一般</span></li>
                <li><i className="customer-level-symbol vip" /><span className="wording">VIP</span></li>
              </ul>
              <div id="resNew">
                <div id="customers">
                  <UI.Common.CustomersList
                    customers={this.state.customers}
                    handleCustomerSelect={this.handleCustomerSelect}
                    selected_customer_id={this.state.selected_customer_id} />
                </div>
              </div>
            </div>
            <div id="customerInfo" className="contBody">
              <div id="basic">
                <dl>
                  <dt>
                    <UI.Select
                      id="customerSts"
                      options={[{label: "一般", value: "regular"}, {label: "VIP", value: "vip"}]}
                      value={this.state.customer.state}
                      data-name="state"
                      className={this.state.customer.state == "vip" ? "vip" : null}
                      onChange={this.handleCustomerDataChange}
                      />
                  </dt>
                  <dd>
                  <input type="text" id="familyName" placeholder="姓"
                    data-name="lastName"
                    value={this.state.customer.lastName}
                    onChange={this.handleCustomerDataChange}
                  />
                  </dd>
                  <dd>
                  <input type="text" id="firstName" placeholder="名"
                    data-name="firstName"
                    value={this.state.customer.firstName}
                    onChange={this.handleCustomerDataChange}
                  />
                  </dd>
                </dl>
                <dl>
                <dt></dt>
                <dd>
                <input type="text" id="familyNameKana" placeholder="せい"
                  data-name="jpLastName"
                  value={this.state.customer.jpLastName}
                  onChange={this.handleCustomerDataChange}
                />
                </dd>
                <dd>
                <input type="text" id="firstNameKana" placeholder="めい"
                  data-name="jpFirstName"
                  value={this.state.customer.jpFirstName}
                  onChange={this.handleCustomerDataChange}
                />
                </dd>
              </dl>
                <dl>
                  <dt>
                    <UI.Select
                      id="phoneType"
                      options={[{label: "自宅", value: "home"}, {label: "携帯", value: "mobile"}]}
                      value={this.state.customer.phoneType}
                      data-name="phoneType"
                      onChange={this.handleCustomerDataChange}
                      />
                  </dt>
                  <dd>
                  <input type="text" id="phone" placeholder="電話番号"
                    data-name="phoneNumber"
                    value={this.state.customer.phoneNumber}
                    onChange={this.handleCustomerDataChange}
                  />
                  </dd>
                  <dd>
                  <input type="date" id="dob" placeholder="お誕生日"
                    data-name="birthday"
                    value={this.state.customer.birthday || ""}
                    onChange={this.handleCustomerDataChange}
                  />
                  </dd>
                </dl>
              </div>
              <div id="tabs" className="tabs">
                <a href="#resList" className="here">利用履歴</a>
                <a href="#detailInfo" className="">顧客情報</a>
              </div>
              <div id="resList" className="tabBody">
                <dl className="tableTTL">
                  <dt className="date">ご利用日</dt>
                  <dt className="time">開始<br />終了</dt>
                  <dt className="calendar">カレンダー</dt>
                  <dt className="menu">メニュー</dt>
                </dl>
                <div id="record">
                </div>
               </div>
              <div id="detailInfo" className="tabBody">
                Detailed Info
              </div>
            </div>

            <div id="mainNav">
              { this.props.fromReservation ? (
                <dl>
                  <dd id="NAVaddCustomer">
                    <a href="#" className="BTNyellow" onClick={this.handleAddCustomerToReservation}>
                      <span>顧客選択</span>
                    </a>
                  </dd>
                  </dl>) : (
                  <div>
                    <dl>
                      <dd id="NAVnewResv">
                        <a href={this.props.addReservationPath} className="BTNtarco"><span>新規予約</span></a>
                      </dd>
                      <dd id="NAVsave">
                        <form id="new_customer_form"
                          acceptCharset="UTF-8" action={this.props.saveCustomerPath} method="post">
                          <input name="customer[id]" type="hidden" value={this.state.customer.id} />
                          <input name="customer[first_name]" type="hidden" value={this.state.customer.firstName} />
                          <input name="customer[last_name]" type="hidden" value={this.state.customer.lastName} />
                          <input name="customer[jp_last_name]" type="hidden" value={this.state.customer.jpLastName} />
                          <input name="customer[jp_first_name]" type="hidden" value={this.state.customer.jpFirstName} />
                          <input name="customer[state]" type="hidden" value={this.state.customer.state} />
                          <input name="customer[phone_type]" type="hidden" value={this.state.customer.phoneType} />
                          <input name="customer[phone_number]" type="hidden" value={this.state.customer.phoneNumber} />
                          <input name="customer[birthday]" type="hidden" value={this.state.customer.birthday} />
                          <input name="authenticity_token" type="hidden" value={this.props.formAuthenticityToken} />
                          <a href="#"
                             className={`BTNyellow ${this.isCustomerdataValid() ? null : "disabled"}`} onClick={this.handleCreateCustomer}><span>上書き保存</span>
                          </a>
                        </form>
                      </dd>
                      { this.state.selected_customer_id ? <dd id="">
                        <a href="#" className="BTNorange" onClick={this.handleDeleteCustomer}>
                          <span>DELETE</span>
                        </a>
                      </dd> : null
                      }
                    </dl>
                    <dl id="calStatus">
                      <dd><span className="reservation-state reserved"></span>予約</dd>
                      <dd><span className="reservation-state checkin"></span>チェックイン</dd>
                      <dd><span className="reservation-state checkout"></span>チェックアウト</dd>
                      <dd><span className="reservation-state noshow"></span>未来店</dd>
                      <dd><span className="reservation-state pending"></span>承認待ち</dd>
                    </dl>
                  </div>
                  )
              }
            </div>
          </div>
          <footer>
          <ul>
              {
               ["あ", "か", "さ", "た", "な", "は", "ま", "や", "ら", "わ", "A"].map(function(symbol, i) {
                 return (
                   <li key={symbol}
                       onClick={this.filterCustomers}
                       value={i} >
                     <a href="#"
                        value={i}
                        className={this.state.selectedFilterPatternNumber == `${i}` ? "here" : null }>{symbol}</a>
                   </li>
                 )
               }.bind(this))
              }
              <li>
                <i className="fa fa-search fa-2x search-symbol" aria-hidden="true"></i>
                <input type="text" id="search" placeholder="Name or TEL" onKeyPress={this.handleSearch} />
              </li>
             </ul>
          </footer>
        </div>
      );
    }
  });

  return CustomersDashboard;
});
