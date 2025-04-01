"use strict";

import React, { useState, useEffect } from "react";
import ImageUploader from "react-images-upload";
import ReactSelect from "react-select";
import TextareaAutosize from 'react-autosize-textarea';

import { useGlobalContext } from "./context/global_state";
import SalesFlowStepIndicator from "./sales_flow_step_indicator";

const StaffSetupStep = ({step, next, prev, lastStep}) => {
  const [submitting, setSubmitting] = useState(false)
  const { props, selected_staff, dispatch, isStaffSetup, isReadyForPreview, createDraftSalesOnlineServicePage } = useGlobalContext()

  useEffect(() => {
    // Auto-select staff if there's only one staff member
    if (props.staffs?.length === 1 && !selected_staff) {
      const onlyStaff = props.staffs[0];
      dispatch({
        type: "SET_ATTRIBUTE",
        payload: {
          attribute: "selected_staff",
          value: onlyStaff.value
        }
      })
    }
  }, [])

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
        {selected_staff && (
          <ImageUploader
            defaultImages={selected_staff?.picture_url?.length ? [selected_staff.picture_url] : []}
            withIcon={false}
            withPreview={true}
            withLabel={false}
            singleImage={true}
            buttonText={I18n.t("user_bot.dashboards.sales.booking_page_creation.staff_picture_requirement_tip")}
            onChange={onDrop}
            imgExtension={[".jpg", ".png", ".jpeg", ".gif"]}
            maxFileSize={5242880}
          />
        )}
        <ReactSelect
          Value={selected_staff ? { label: selected_staff.name } : ""}
          defaultValue={selected_staff ?  { label: selected_staff.name } : ""}
          placeholder={I18n.t("common.select_a_staff")}
          options={props.staffs}
          onChange={
            (staff_option)=> {
              dispatch({
                type: "SET_ATTRIBUTE",
                payload: {
                  attribute: "selected_staff",
                  value: staff_option.value
                }
              })
            }
          }
        />

        {selected_staff?.editable ? (
          <TextareaAutosize
            className="extend with-border"
            value={selected_staff?.introduction || ""}
            placeholder={I18n.t("user_bot.dashboards.sales.booking_page_creation.staff_introduction")}
            onChange={(event) => {
              dispatch({
                type: "SET_NESTED_ATTRIBUTE",
                payload: {
                  parent_attribute: "selected_staff",
                  attribute: "introduction",
                  value: event.target.value
                }
              })
            }}
          />

        ) : (
          <p className="break-line-content">
            {selected_staff?.introduction}
          </p>
        )}

        <p className="message margin-around centerize">
          {I18n.t("user_bot.dashboards.sales.booking_page_creation.staff_change_tip")}
        </p>
        <div className="action-block">
          <button onClick={prev} className="btn btn-tarco">
            {I18n.t("action.prev_step")}
          </button>
          <button
            className="btn btn-gray"
            disabled={submitting}
            onClick={async () => {
              if (submitting) return;
              setSubmitting(true)
              await createDraftSalesOnlineServicePage()
            }}>
            {submitting ? (
              <i className="fa fa-spinner fa-spin fa-fw fa-2x" aria-hidden="true"></i>
            ) : (
              I18n.t("action.save_as_draft")
            )}
          </button>
          <button onClick={() => {(isReadyForPreview()) ? lastStep(2) : next()}} className="btn btn-yellow"
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
