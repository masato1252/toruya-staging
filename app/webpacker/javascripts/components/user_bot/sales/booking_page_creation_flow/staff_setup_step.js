"use strict";

import React from "react";
import ImageUploader from "react-images-upload";
import ReactSelect from "react-select";
import TextareaAutosize from 'react-autosize-textarea';

import { useGlobalContext } from "./context/global_state";
import SalesFlowStepIndicator from "./sales_flow_step_indicator";
import FlowEdit from "components/user_bot/sales/flow_edit";

const StaffSetupStep = ({step, next, prev, jump}) => {
  const { props, selected_staff, dispatch, isStaffSetup, isReadyForPreview } = useGlobalContext()

  const onDrop = (picture, pictureDataUrl) => {
    dispatch({
      type: "SET_NESTED_ATTRIBUTE",
      payload: {
        parent_attribute: "selected_staff",
        attribute: "picture",
        value: picture[0]
      }
    })

    dispatch({
      type: "SET_NESTED_ATTRIBUTE",
      payload: {
        parent_attribute: "selected_staff",
        attribute: "picture_url",
        value: pictureDataUrl
      }
    })
  }

  return (
    <div className="form staff-profile">
      <SalesFlowStepIndicator step={step} />
      <h4 className="header centerize"
        dangerouslySetInnerHTML={{ __html: I18n.t("user_bot.dashboards.sales.booking_page_creation.introduce_who_do_this") }} />
      <div className="product-content-deails">
        <StaffEdit
          staffs={props.staffs}
          selected_staff={selected_staff}
          handleStaffChange={(attr, value) => {
            if (attr === "selected_staff") {
              dispatch({
                type: "SET_ATTRIBUTE",
                payload: {
                  attribute: "selected_staff",
                  value: value
                }
              })
            }
            else if (attr === "introduction") {
              dispatch({
                type: "SET_NESTED_ATTRIBUTE",
                payload: {
                  parent_attribute: "selected_staff",
                  attribute: "introduction",
                  value: value
                }
              })
            }
          }}
          handlePictureChange={onDrop}
        />

        <div className="action-block">
          <button onClick={prev} className="btn btn-tarco">
            {I18n.t("action.prev_step")}
          </button>
          <button onClick={() => {(isReadyForPreview()) ? jump(7) : next()}} className="btn btn-yellow"
            disabled={!isStaffSetup()}
          >
            {I18n.t("action.next_step")}
          </button>
        </div>
      </div>
    </div>
  )
}

export default StaffSetupStep
