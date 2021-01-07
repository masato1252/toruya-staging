"use strict";

import React from "react";

const SaleTemplateContainer = ({shop, product, template_id, children}) => {
  return (
    <div className="sale-template-container">
      <div className="sale-template-header">
        { shop.logo_url ?  <img className="logo" src={shop.logo_url} /> : <span>{shop.name}</span>}
        { template_id ? <span className="template-version-mark">{`テンプレート${template_id}`}</span> : "" }
      </div>
      {children}
    </div>
  )
}

export default SaleTemplateContainer;
