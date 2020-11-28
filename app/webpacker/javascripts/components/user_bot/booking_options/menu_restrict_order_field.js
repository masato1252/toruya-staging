"use strict"

import React from "react";

const MenuRestrictOrderField = ({i18n, register}) => {
  return (
    <>
      <div className="field-row">
        <label>
          <input name="menu_restrict_order" type="radio" value="false" ref={register({ required: true })} />
          {i18n.menu_restrict_dont_need_order}
        </label>
      </div>
      <div className="field-row">
        <label>
          <input name="menu_restrict_order" type="radio" value="true" ref={register({ required: true })} />
          {i18n.menu_restrict_order}
        </label>
      </div>
    </>
  )
}

export default MenuRestrictOrderField;
