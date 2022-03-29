"use strict";

import React from "react";
import I18n from 'i18n-js/index.js.erb';

const SellingEndTimeEdit = ({end_time, handleEndTimeChange, default_option = "end_at"}) => (
  <>
    <div className="margin-around">
      <label className="">
        <div>
          <input name="end_type" type="radio" value="end_at"
            checked={end_time.end_type === "end_at"}
            onChange={() => {
              handleEndTimeChange({
                end_type: "end_at"
              })
            }}
          />
          {I18n.t("user_bot.dashboards.sales.online_service_creation.selling_end_on")}{default_option == "end_at" ? I18n.t("common.recommend") : ""}
        </div>
        {end_time.end_type === "end_at" && (
          <input
            name="end_time_date_part"
            type="date"
            value={end_time.end_time_date_part || ""}
            onChange={(event) => {
              handleEndTimeChange({
                end_type: "end_at",
                end_time_date_part: event.target.value
              })
            }}
          />
        )}
      </label>
    </div>

    <div className="margin-around">
      <label className="">
        <input name="end_type" type="radio" value="never"
          checked={end_time.end_type === "never"}
          onChange={() => {
            handleEndTimeChange({
              end_type: "never"
            })
          }}
        />
        {I18n.t("user_bot.dashboards.sales.online_service_creation.selling_forever")}{default_option == "never" ? I18n.t("common.recommend") : ""}
      </label>
    </div>
  </>
)

export default SellingEndTimeEdit
