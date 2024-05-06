"use strict";

import React from "react";

const DraftWarning = ({i18n, booking_page}) => {
  if (booking_page.draft) {
    return (
      <div className="alert alert-info">{i18n.showing_preview}</div>
    )
  }
  else {
    return <></>
  }
}

export default DraftWarning;
