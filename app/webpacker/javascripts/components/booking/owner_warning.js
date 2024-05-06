"use strict";

import React from "react";

const OwnerWarning = ({i18n, is_shop_owner, is_done}) => {
  const {
    owner_warning1,
    owner_warning2
  } = i18n.done

  if (!is_shop_owner) return <></>

  if (is_done) {
    return (
      <div className="notification alert alert-info fade in centerize">
        {owner_warning1}
        <br />
        {owner_warning2}
      </div>
    )
  }
  else {
    return (
      <div className="notification alert alert-info fade in centerize">
        {i18n.owner_personal_schedule_warning}
      </div>
    )
  }
}

export default OwnerWarning;
