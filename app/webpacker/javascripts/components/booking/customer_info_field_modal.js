"use strict";

import React from "react";

const CustomerInfoFieldModel = ({ set_booking_reservation_form_values, booking_reservation_form_values, i18n }) => {
  const field_name = booking_reservation_form_values.customer_info_field_name;
  const { last_name, first_name, phonetic_last_name, phonetic_first_name, phone_number, email, address_details } = booking_reservation_form_values.customer_info

  const { name, phonetic_name, save_change, invalid_to_change, info_change_title } = i18n;
  const isAnyErrors = () => {
    return booking_reservation_form_values.errors && Object.keys(booking_reservation_form_values.errors).length
  }

  const renderField = (field_name) => {
    switch(field_name) {
      case "full_name":
        return (
          <>
            <h4>
              {name}
            </h4>
            <input
              value={last_name || ""}
              onChange={(event) => {
                event.persist();
                set_booking_reservation_form_values(prev => ({...prev,  customer_info: {...prev.customer_info, last_name: event.target?.value }}))
              }}
              name="booking_reservation_form[customer_info][last_name]"
              type="text"
              placeholder={i18n.last_name}
            />
            <input
              value={first_name || ""}
              onChange={(event) => {
                event.persist();
                set_booking_reservation_form_values(prev => ({...prev,  customer_info: {...prev.customer_info, first_name: event.target?.value }}))
              }}
              name="booking_reservation_form[customer_info][first_name]"
              type="text"
              placeholder={i18n.first_name}
            />
          </>
        )
      case "phonetic_full_name":
        return (
          <>
            <h4>
              {phonetic_name}
            </h4>
            <input
              value={phonetic_last_name || ""}
              onChange={(event) => {
                event.persist();
                set_booking_reservation_form_values(prev => ({...prev,  customer_info: {...prev.customer_info, phonetic_last_name: event.target?.value }}))
              }}
              name="booking_reservation_form[customer_info][phonetic_last_name]"
              type="text"
              placeholder={i18n.phonetic_last_name}
            />
            <input
              value={phonetic_first_name || ""}
              onChange={(event) => {
                event.persist();
                set_booking_reservation_form_values(prev => ({...prev,  customer_info: {...prev.customer_info, phonetic_first_name: event.target?.value }}))
              }}
              name="booking_reservation_form[customer_info][phonetic_first_name]"
              type="text"
              placeholder={i18n.phonetic_first_name}
            />
          </>
        )
      case "phone_number":
        return (
          <>
            <h4>
              {i18n.phone_number}
            </h4>
            <input
              value={phone_number || ""}
              onChange={(event) => {
                event.persist();
                set_booking_reservation_form_values(prev => ({...prev,  customer_info: {...prev.customer_info, phone_number: event.target?.value }}))
              }}
              name="booking_reservation_form[customer_info][phone_number]"
              type="tel"
              placeholder="01234567891"
            />
          </>
        )
      case "email":
        return (
          <>
            <h4>
              {i18n.email}
            </h4>
            <input
              value={email || ""}
              onChange={(event) => {
                event.persist();
                set_booking_reservation_form_values(prev => ({...prev,  customer_info: {...prev.customer_info, email: event.target?.value }}))
              }}
              name="booking_reservation_form[customer_info][email]"
              type="text"
              placeholder="mail@domain.com"
            />
          </>
        )
      case "address_details":
        return (
          <>
            <h4>
              {i18n.address_details.zipcode}
            </h4>
            <input
              value={address_details?.zip_code || ""}
              onChange={(event) => {
                event.persist();
                set_booking_reservation_form_values(prev => ({...prev,  customer_info: {...prev.customer_info, address_details: { ...prev.customer_info?.address_details, zip_code: event.target?.value } }}))
              }}
              name="booking_reservation_form[customer_info][address_details][zip_code]"
              type="tel"
              placeholder="1234567"
            />
            <h4>
              {i18n.address_details.living_state}
            </h4>
            <input
              value={address_details?.region || ""}
              onChange={(event) => {
                event.persist();
                set_booking_reservation_form_values(prev => ({...prev,  customer_info: {...prev.customer_info, address_details: { ...prev.customer_info?.address_details, region: event.target?.value } }}))
              }}
              name="booking_reservation_form[customer_info][address_details][region]"
              type="text"
              placeholder={I18n.t("common.address_region")}
            />
            <h4>
              {i18n.address_details.city}
            </h4>
            <input
              value={address_details?.city || ""}
              onChange={(event) => {
                event.persist();
                set_booking_reservation_form_values(prev => ({...prev,  customer_info: {...prev.customer_info, address_details: { ...prev.customer_info?.address_details, city: event.target?.value } }}))
              }}
              name="booking_reservation_form[customer_info][address_details][city]"
              type="text"
              placeholder={I18n.t("common.address_city")}
            />
            <h4>
              {i18n.address_details.street1}
            </h4>
            <input
              value={address_details?.street1 || ""}
              onChange={(event) => {
                event.persist();
                set_booking_reservation_form_values(prev => ({...prev,  customer_info: {...prev.customer_info, address_details: { ...prev.customer_info?.address_details, street1: event.target?.value } }}))
              }}
              name="booking_reservation_form[customer_info][address_details][street1]"
              type="text"
              className="street-field"
              placeholder={I18n.t("common.address_street1")}
            />
            <h4>
              {i18n.address_details.street2}
            </h4>
            <input
              value={address_details?.street2 || ""}
              onChange={(event) => {
                event.persist();
                set_booking_reservation_form_values(prev => ({...prev,  customer_info: {...prev.customer_info, address_details: { ...prev.customer_info?.address_details, street2: event.target?.value } }}))
              }}
              name="booking_reservation_form[customer_info][address_details][street2]"
              type="text"
              className="street-field"
              placeholder={I18n.t("common.address_street2")}
            />
          </>
        )
      default:
        return <></>
    }
  }

  return (
    <div className="modal fade" id="customer-info-field-modal" tabIndex="-1" role="dialog">
      <div className="modal-dialog" role="document">
        <div className="modal-content">
          <div className="modal-header">
            { isAnyErrors() ? null : (
              <button type="button" className="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>
            )}
            <h4 className="modal-title">
              {info_change_title}
            </h4>
          </div>
          <div className="modal-body">
            {renderField(field_name)}
          </div>
          <div className="modal-footer centerize">
            { isAnyErrors() ? (
              <button type="button" className="btn btn-tarco disabled" disabled="true">
                {invalid_to_change}
              </button>
            ) : (
              <button type="button" className="btn btn-tarco" data-dismiss="modal" aria-label="Close">
                {save_change}
              </button>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}

export default CustomerInfoFieldModel
