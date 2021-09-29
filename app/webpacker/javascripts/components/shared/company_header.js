"use strict";

import React from "react";

const CompanyHeader = ({shop, children}) => {
  return (
    <>
      <div className="company-header">
        { shop.logo_url ?  <img className="logo" src={shop.logo_url} /> : <h2>{shop.name}</h2> }
      </div>
      {children}
    </>
  )
}

export default CompanyHeader;
