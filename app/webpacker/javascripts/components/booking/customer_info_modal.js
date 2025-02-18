"use strict";

import React from "react";

const CustomerInfoModal = ({
  set_booking_reservation_form_values, booking_reservation_form_values, i18n, support_phonetic_name
}) => {
  const { last_name, first_name, phonetic_last_name, phonetic_first_name, phone_number, email, address_details } = booking_reservation_form_values.customer_info;

  const customerInfoFieldModalHideHandler = () => {
    $("#customer-info-modal").modal("show");
  }

  const openCustomerInfoFieldModel = (field_name) => {
    set_booking_reservation_form_values(prev => ({...prev, customer_info_field_name: field_name}))

    $("#customer-info-modal").modal("hide")
    $("#customer-info-field-modal").on("hidden.bs.modal", customerInfoFieldModalHideHandler);
    $("#customer-info-field-modal").modal({
      backdrop: "static",
      keyboard: false,
      show: true
    })
  }

  return (
    <div className="modal fade" id="customer-info-modal" tabIndex="-1" role="dialog">
      <div className="modal-dialog" role="document">
        <div className="modal-content">
          <div className="modal-header">
            <button type="button" className="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>
            <h4 className="modal-title">
              {i18n.info_change_title}
            </h4>
          </div>
          <div className="modal-body">
            <h4>
              {i18n.name}
              <a href="#" className="edit" onClick={() => openCustomerInfoFieldModel("full_name")}>{i18n.edit}</a>
            </h4>
            <div className="info">
              {last_name} {first_name}
            </div>
            {support_phonetic_name && (
              <>
                <h4>
                  {i18n.phonetic_name}
                  <a href="#" className="edit" onClick={() => openCustomerInfoFieldModel("phonetic_full_name")}>{i18n.edit}</a>
                </h4>
                <div className="info">
                  {phonetic_last_name} {phonetic_first_name}
                </div>
              </>
            )}
            <h4>
              {i18n.address}
              <a href="#" className="edit" onClick={() => openCustomerInfoFieldModel("address_details")}>{i18n.edit}</a>
            </h4>
            <div className="info">
              {address_details && address_details.zip_code && `〒${address_details.zip_code}`} {address_details && address_details.region} {address_details && address_details.city} {address_details && address_details.street1} {address_details && address_details.street2}
            </div>
          </div>
          <div className="modal-footer centerize">
            <button type="button" className="btn btn-tarco" data-dismiss="modal" aria-label="Close">
              OK
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}

export default CustomerInfoModal
