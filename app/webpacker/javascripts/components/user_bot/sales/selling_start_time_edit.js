"use strict";

import React from "react";
import I18n from 'i18n-js/index.js.erb';

const SellingStartTimeEdit = ({start_time, handleStartTimeChange}) => (
  <>
    <div className="margin-around">
      <label className="">
        <div>
          <input name="start_type" type="radio" value="start_at"
            checked={start_time.start_type === "start_at"}
            onChange={() => {
              handleStartTimeChange({
                start_type: "start_at"
              })
            }}
          />
          {I18n.t("sales.start_at")}
        </div>
        {start_time.start_type === "start_at" && (
          <input
            name="start_time_date_part"
            type="date"
            value={start_time.start_time_date_part || ""}
            onChange={(event) => {
              handleStartTimeChange({
                start_type: "start_at",
                start_time_date_part: event.target.value
              })
            }}
          />
        )}
      </label>
    </div>

    <div className="margin-around">
      <label className="">
        <input name="start_type" type="radio" value="now"
          checked={start_time.start_type === "now"}
          onChange={() => {
            handleStartTimeChange({
              start_type: "now"
            })
          }}
        />
        {I18n.t("sales.sale_today")}
      </label>
    </div>
  </>
)

export default SellingStartTimeEdit
