"use strict";

UI.define("Customers.CustomerInfoView", function() {
  var CustomerInfoView = React.createClass({
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
                <ul>
                  {this.props.customer.groupName ?
                    <li>{this.props.customer.groupName}</li> : null
                  }
                  <li className="vip">VIP</li>
                </ul>
              </dt>
              <dd>
                <ul className="kana">
                  <li>{this.props.customer.phoneticFirstName}　{this.props.customer.phoneticLastName}</li>
                </ul>
                <ul><li>{this.props.customer.lastName} {this.props.customer.firstName}</li></ul>
              </dd>
              <dd>
                <a href="tel:08036238534" className="BTNtarco">
                  <i className="fa fa-phone fa-2x" aria-hidden="true" title="call"></i>
                </a>
                <a href="mail:studioha3@softbank.ne.jp" className="BTNtarco">
                  <i className="fa fa-envelope fa-2x" aria-hidden="true" title="mail"></i>
                </a>
              </dd>
            </dl>
          </div>

          <div id="tabs" className="tabs">
            <a href="customer.html" className="">利用履歴</a>
            <a href="#" className="here">顧客情報</a>
          </div>
          <div id="detailInfo" className="tabBody" style={{height: "425px"}}>
            <ul className="functions"><li className="right"><a href="customer_info_edit.html">EDIT</a></li></ul>
            <dl className="Address">
              <dt>Address</dt>
              <dd>{this.props.customer.address}</dd>
            </dl>
            <dl className="phone">
              <dt>Phone</dt>
              <dd>
                <a href="tel:0524095796" className="BTNtarco">
                  <i className="fa fa-home fa-2x" aria-hidden="true" title="Home"></i>
                </a>
              </dd>
            </dl>
            <dl className="email">
              <dt>Email</dt>
              <dd>
                <a href="mail:taiwanhimawari@gmail.com" className="BTNtarco">
                  <i className="fa fa-home fa-2x" aria-hidden="true" title="Home"></i>
                </a>
              </dd>
            </dl>
            <div className="others">
              <dl className="customerID"><dt>顧客ID</dt><dd>DHS0001</dd></dl>
              <dl className="dob"><dt>DOB</dt><dd>{this.props.customer.birthday}</dd></dl>
              <dl className="memo"><dt>Memo</dt><dd>hahaha its's a memo</dd></dl>
            </div>
          </div>
        </div>
      );
    }
  });

  return CustomerInfoView;
});
