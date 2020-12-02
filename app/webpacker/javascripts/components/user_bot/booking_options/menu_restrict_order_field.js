"use strict"

import React from "react";

const MenuRestrictOrderField = ({i18n, register}) => {
  return (
    <>
      <label className="field-row flex-start radio-row">
        <input name="menu_restrict_order" type="radio" value="false" ref={register({ required: true })} />
        <span>{i18n.menu_restrict_dont_need_order}</span>
      </label>
      <label className="field-row flex-start radio-row">
        <input name="menu_restrict_order" type="radio" value="true" ref={register({ required: true })} />
        <span>{i18n.menu_restrict_order}</span>
      </label>
    </>
  )
}

export default MenuRestrictOrderField;
