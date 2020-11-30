"use strict"

import React from "react";

const MenuRestrictOrderField = ({i18n, register}) => {
  return (
    <>
      <label className="field-row flex-start">
        <input name="menu_restrict_order" type="radio" value="false" ref={register({ required: true })} />
        {i18n.menu_restrict_dont_need_order}
      </label>
      <label className="field-row flex-start">
        <input name="menu_restrict_order" type="radio" value="true" ref={register({ required: true })} />
        {i18n.menu_restrict_order}
      </label>
    </>
  )
}

export default MenuRestrictOrderField;
