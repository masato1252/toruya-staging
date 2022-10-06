"use strict";

import React from "react";
import I18n from 'i18n-js/index.js.erb';

const SaleDemoPage = ({shop}) => {
  const name = shop?.company_name || shop.name;
  const phone_number = shop?.company_phone_number || shop.phone_number;
  const logo_url = shop?.logo || shop.logo_url

  return (
    <div className="sale-page centerize">
      <div className="sale-template-container">
        <div className="sale-template-header">
          { logo_url?.length ?  <img className="logo" src={logo_url} /> : <h2>{name}</h2> }
        </div>
        <div className='demo-content-placeholder'></div>

        <div className="shop-content content">
          <div><b>{name}</b></div>
          <div>{shop.address}</div>
          {phone_number && <div><i className="fa fa-phone"></i> <a href={`tel:${phone_number}`}>{phone_number}</a></div>}
          {shop.email && <div><i className="fa fa-envelope"></i> {shop.email}</div>}
        </div>
      </div>
    </div>
  )
}

export default SaleDemoPage;
