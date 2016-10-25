"use strict";

UI.define("Customers.CustomerInfo", function() {
  var CustomerInfo = React.createClass({
    getInitialState: function() {
      return ({
      });
    },

    render: function() {
      return (
        <div id="customerInfo" className="contBody">
          <div id="basic">
            <dl>
              <dt>
                <UI.Select
                  id="customerSts"
                  options={[{label: "一般", value: "regular"}, {label: "VIP", value: "vip"}]}
                  value={this.props.customer.state}
                  data-name="state"
                  className={this.props.customer.state == "vip" ? "vip" : null}
                  onChange={this.props.handleCustomerDataChange}
                  />
              </dt>
              <dd>
              <input type="text" id="familyName" placeholder="姓"
                data-name="lastName"
                value={this.props.customer.lastName}
                onChange={this.props.handleCustomerDataChange}
              />
              </dd>
              <dd>
              <input type="text" id="firstName" placeholder="名"
                data-name="firstName"
                value={this.props.customer.firstName}
                onChange={this.props.handleCustomerDataChange}
              />
              </dd>
            </dl>
            <dl>
            <dt></dt>
            <dd>
            <input type="text" id="familyNameKana" placeholder="せい"
              data-name="jpLastName"
              value={this.props.customer.jpLastName}
              onChange={this.props.handleCustomerDataChange}
            />
            </dd>
            <dd>
            <input type="text" id="firstNameKana" placeholder="めい"
              data-name="jpFirstName"
              value={this.props.customer.jpFirstName}
              onChange={this.props.handleCustomerDataChange}
            />
            </dd>
          </dl>
            <dl>
              <dt>
                <UI.Select
                  id="phoneType"
                  options={[{label: "自宅", value: "home"}, {label: "携帯", value: "mobile"}]}
                  value={this.props.customer.phoneType}
                  data-name="phoneType"
                  onChange={this.props.handleCustomerDataChange}
                  />
              </dt>
              <dd>
              <input type="text" id="phone" placeholder="電話番号"
                data-name="phoneNumber"
                value={this.props.customer.phoneNumber}
                onChange={this.props.handleCustomerDataChange}
              />
              </dd>
              <dd>
              <input type="date" id="dob" placeholder="お誕生日"
                data-name="birthday"
                value={this.props.customer.birthday || ""}
                onChange={this.props.handleCustomerDataChange}
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
      );
    }
  });
  return CustomerInfo;
});
