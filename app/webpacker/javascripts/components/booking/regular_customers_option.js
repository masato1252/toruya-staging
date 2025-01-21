"use strict";

import React from "react";
import PhoneInput from 'react-phone-input-2'

import { ErrorMessage } from "shared/components";

const RegularCustomersOption = ({
  set_booking_reservation_form_values,
  booking_reservation_form_values,
  isCustomerTrusted,
  i18n,
  findCustomer,
  support_phonetic_name,
  locale
}) => {
  const phone_countries = ['jp', 'ca', 'us', 'mx', 'in', 'ru', 'id', 'cn', 'hk', 'kr', 'my', 'sg', 'tw', 'tr', 'fr', 'de', 'it', 'dk', 'fi', 'is', 'uk', 'ar', 'br', 'au', 'nz']
  const {
    found_customer,
    is_finding_customer,
    customer_last_name,
    customer_first_name,
    customer_phonetic_last_name,
    customer_phonetic_first_name,
    customer_phone_number
  } = booking_reservation_form_values;

  const {
    customer_phonetic_name_failed_message,
    customer_last_name_failed_message,
    customer_first_name_failed_message
  } = booking_reservation_form_values.errors || {};

  if (found_customer) return <></>;
  if (isCustomerTrusted) return <></>;

  const { name, last_name, first_name, phonetic_last_name, phonetic_first_name, phone_number, why_need_phone_number, next_step } = i18n;

  return (
    <div className="customer-type-options">
      <h4>
        {name}
      </h4>
      <div>
        <input
          name="booking_reservation_form[customer_last_name]"
          type="text"
          placeholder={last_name}
          value={customer_last_name || ""}
          onChange={(event) => {
            event.persist();
            set_booking_reservation_form_values(prev => ({...prev, customer_last_name: event.target?.value}))
          }}
        />
        <ErrorMessage error={customer_last_name_failed_message} />
        <input
          name="booking_reservation_form[customer_first_name]"
          type="text"
          placeholder={first_name}
          value={customer_first_name || ""}
          onChange={(event) => {
            event.persist();
            set_booking_reservation_form_values(prev => ({...prev, customer_first_name: event.target?.value}))
          }}
        />
        <ErrorMessage error={customer_first_name_failed_message} />
      </div>
      {support_phonetic_name && (
        <>
          <br />
          <div>
          <input
            id="customer_phonetic_last_name"
            name="booking_reservation_form[customer_phonetic_last_name]"
            type="text"
            placeholder={phonetic_last_name}
            value={customer_phonetic_last_name || ""}
            onChange={(event) => {
              event.persist();
              set_booking_reservation_form_values(prev => ({...prev, customer_phonetic_last_name: event.target?.value}))
            }}
          />
          <p></p>
          <input
            id="customer_phonetic_first_name"
            name="booking_reservation_form[customer_phonetic_first_name]"
            type="text"
            placeholder={phonetic_first_name}
            value={customer_phonetic_first_name || ""}
            onChange={(event) => {
              event.persist();
              set_booking_reservation_form_values(prev => ({...prev, customer_phonetic_first_name: event.target?.value}))
            }}
          />
            <ErrorMessage error={customer_phonetic_name_failed_message} />
          </div>
        </>
      )}
      <h4>
        {phone_number}{why_need_phone_number}
      </h4>
      <PhoneInput
        country={phone_countries.includes(locale) ? locale : 'jp'}
        onlyCountries={phone_countries}
        value={customer_phone_number || ""}
        onChange={(phone) => {
          set_booking_reservation_form_values(prev => ({...prev, customer_phone_number: phone}))
        }}
        autoFormat={false}
        placeholder="09012345678"
      />
      {!found_customer && (
        <div className="centerize">
          <a href="#" className="btn btn-tarco find-customer" onClick={findCustomer} disabled={is_finding_customer}>
            {is_finding_customer ? <i className="fa fa-spinner fa-spin fa-fw fa-2x" aria-hidden="true"></i> : next_step}
          </a>
        </div>
      )}
    </div>
  )
}

export default RegularCustomersOption
