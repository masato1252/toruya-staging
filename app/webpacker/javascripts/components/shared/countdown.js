"use strict";

import React from "react";
import I18n from 'i18n-js/index.js.erb';
import Countdown from 'react-countdown';

const CommonCountdown = ({end_at, completedView, noEndView}) => {
  const renderer = ({ days, hours, minutes, seconds, completed }) => {
    if (completed) {
      return (completedView || <></>);
    } else {
      return (
        <span className="countdown">
          <span className="number">{days}</span>{I18n.t("common.day_word")}
          <span className="number">{hours}</span>{I18n.t("common.hour_word")}
          <span className="number">{minutes}</span>{I18n.t("common.minute_word")}
          <span className="number">{seconds}</span>{I18n.t("common.second_word")}
        </span>
      )
    }
  };

  if (!end_at) return (noEndView || <></>)

  return (
    <Countdown
      date={end_at}
      renderer={renderer}
    />
  )
}

export default CommonCountdown
