import React from "react";
import ImageUploader from "react-images-upload";
import TextareaAutosize from 'react-autosize-textarea';

import I18n from 'i18n-js/index.js.erb';

const StaffEdit = ({staffs, selected_staff, handleStaffChange, handlePictureChange}) => {
  return (
    <div className="sales">
      <div className="staff-profile">
        {selected_staff && (
          <ImageUploader
            defaultImages={selected_staff?.picture_url?.length ? [selected_staff.picture_url] : []}
            withIcon={false}
            withPreview={true}
            withLabel={false}
            singleImage={true}
            buttonText={I18n.t("user_bot.dashboards.sales.booking_page_creation.staff_picture_requirement_tip")}
            onChange={handlePictureChange}
            imgExtension={[".jpg", ".png", ".jpeg", ".gif"]}
            maxFileSize={5242880}
          />
        )}
        <ReactSelect
          Value={selected_staff ? { label: selected_staff.name } : ""}
          defaultValue={selected_staff ?  { label: selected_staff.name } : ""}
          placeholder={I18n.t("common.select_a_staff")}
          options={staffs}
          onChange={
            (staff_option)=> {
              handleStaffChange("selected_staff", staff_option.value)
            }
          }
        />

        {selected_staff?.editable ? (
          <TextareaAutosize
            className="extend with-border"
            value={selected_staff?.introduction || ""}
            placeholder={I18n.t("user_bot.dashboards.sales.booking_page_creation.staff_introduction")}
            onChange={(event) => {
              handleStaffChange("introduction", event.target.value)
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
      </div>
    </div>
  )
}

export default StaffEdit
