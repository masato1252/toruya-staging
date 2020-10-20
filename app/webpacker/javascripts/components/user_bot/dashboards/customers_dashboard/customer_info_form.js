"use strict"

import React, { useContext, useEffect, useState } from "react";
import { useForm, useFieldArray } from "react-hook-form";
import _ from "lodash";

import { GlobalContext } from "context/user_bots/customers_dashboard/global_state";
import { TopNavigationBar, SelectOptions } from "shared/components"
import { CustomerServices } from "user_bot/api"
import useAddress from "libraries/use_address";
import ProcessingBar from "shared/processing_bar.js"

const TopBar = () => {
  return (
    <TopNavigationBar
      leading={<i className="fa fa-angle-left fa-2x"></i>}
      title={"Customer Edit"}
    />
  )
}

const UserBotCustomerInfoForm = () => {
  const { selected_customer, props } = useContext(GlobalContext)
  const { i18n } = props

  const { register, watch, setValue, control, handleSubmit, formState } = useForm({
    defaultValues: {
      id: selected_customer.id,
      last_name: selected_customer.lastName,
      first_name: selected_customer.firstName,
      phonetic_last_name: selected_customer.phoneticLastName,
      phonetic_first_name: selected_customer.phoneticFirstName,
      contact_group_id: selected_customer.contactGroupId,
      rank_id: selected_customer.rankId,
      address_details: _.merge(selected_customer.addressDetails, { zip_code: selected_customer.addressDetails?.zipCode }),
      phone_numbers_details: selected_customer.phoneNumbersDetails,
      emails_details: selected_customer.emailsDetails,
      custom_id: selected_customer.customId,
      birthday: selected_customer.birthday,
      memo: selected_customer.memo
    }
  });

  const { isSubmitting } = formState;
  const address = useAddress(watch("address_details[zip_code]"))

  const phone_number_fields = useFieldArray({
    control: control,
    name: "phone_numbers_details"
  });

  const email_fields = useFieldArray({
    control: control,
    name: "emails_details"
  });

  useEffect(() => {
    setValue("address_details[region]", address?.prefecture)
    setValue("address_details[city]", address?.city)
  }, [address.city])

  const itemOptions = (items) => {
    var options = [
      { label: i18n.home, value: "home" },
      { label: i18n.mobile, value: "mobile" },
      { label: i18n.work, value: "work" }
    ];

    (items || []).forEach((item) => {
      if (!_.includes(options.map((option) => option["value"]), item.type)) {
        options.push(
          { label: item.type, value: item.type }
        )
      }
    });

    return options;
  };

  const onSubmit = async (data) => {
    console.log(data)

    let error, response;

    [error, response] = await CustomerServices.save(data)

    window.location = response.data.redirect_to
  }

  return (
    <div className="customer-view form">
      <ProcessingBar processing={isSubmitting} />
      <TopBar />
      <input ref={register} name="id" type="hidden" />

      <div className="customer-edit">
        <div className="field-row" >
          <span>group</span>
          <select name="contact_group_id" ref={register({ required: true })}>
            <option>{i18n.group_blank_option}</option>
            <SelectOptions options={props.contact_groups} />
          </select>
        </div>
        <div className="field-row" >
          <span>rank</span>
          <select name="rank_id" ref={register({ required: true })}>
            <SelectOptions options={props.ranks} />
          </select>
        </div>

        <div className="field-header">Name</div>
        <div className="field-row" >
          <span>Last Name</span>
          <span>
            <input
              ref={register({ required: true })}
              name="last_name"
              placeholder="last_name"
              type="text"
            />
          </span>
        </div>
        <div className="field-row" >
          <span>First Name</span>
          <span>
            <input
              ref={register({ required: true })}
              name="first_name"
              placeholder="first_name"
              type="text"
            />
          </span>
        </div>
        <div className="field-row" >
          <span>phonetic_last_name</span>
          <span>
            <input
              ref={register}
              name="phonetic_last_name"
              placeholder="phonetic_last_name"
              type="text"
            />
          </span>
        </div>
        <div className="field-row" >
          <span>phonetic_first_name</span>
          <span>
            <input
              ref={register}
              name="phonetic_first_name"
              placeholder="phonetic_first_name"
              type="text"
            />
          </span>
        </div>

        <div className="field-header">Address</div>
        <div className="field-row" >
          <span>zipcode</span>
          <input
            ref={register}
            name="address_details[zip_code]"
            placeholder="1234567"
            type="tel"
          />
        </div>
        <div className="field-row">
          <span>region</span>
          <input
            ref={register}
            name="address_details[region]"
            placeholder={`region`}
            type="text"
          />
        </div>
        <div className="field-row">
          <span>city</span>
          <input
            ref={register}
            name="address_details[city]"
            placeholder={`city`}
            type="text"
          />
        </div>
        <div className="field-row">
          <span>street1</span>
          <input
            ref={register}
            name="address_details[street1]"
            placeholder={`street1`}
            type="text"
          />
        </div>
        <div className="field-row">
          <span>street2</span>
          <input
            ref={register}
            name="address_details[street2]"
            placeholder={`street2`}
            type="text"
          />
        </div>

        <div className="field-header">Phone Number</div>
        {phone_number_fields.fields.map((field, index) => (
          <div key={field.id} className="field-row">
            <select name={`phone_numbers_details[${index}].type`} ref={register({})} defaultValue={field.type}>
              <SelectOptions options={itemOptions(phone_number_fields.fields)} />
            </select>

            <input
              type="text"
              name={`phone_numbers_details[${index}].value`}
              ref={register({})}
              defaultValue={field.value}
            />
            <button className="btn btn-orange" onClick={() => phone_number_fields.remove(index)}>
              <i className="fa fa-minus"></i>
            </button>
          </div>
        ))}

        <div className="field-row">
          <button className="btn btn-yellow" onClick={() => phone_number_fields.append({type: "mobile", value: ""})}>
            <i className="fa fa-plus"></i>
          </button>
        </div>

        <div className="field-header">Emails</div>
        {email_fields.fields.map((field, index) => (
          <div key={field.id} className="field-row">
            <select name={`emails_details[${index}].type`} ref={register({})} defaultValue={field.type}>
              <SelectOptions options={itemOptions(email_fields.fields)} />
            </select>

            <input
              type="text"
              name={`emails_details[${index}].value`}
              ref={register({})}
              defaultValue={field.value}
            />

            <button className="btn btn-orange" onClick={() => email_fields.remove(index)}>
              <i className="fa fa-minus"></i>
            </button>
          </div>
        ))}
        <div className="field-row">
          <button className="btn btn-yellow" onClick={() => email_fields.append({type: "work", value: ""})}>
            <i className="fa fa-plus"></i>
          </button>
        </div>

        <div className="field-header">others</div>
        <div className="field-row">
          <span>custom id</span>
          <input
            ref={register}
            name="custom_id"
            placeholder={`custom_id`}
            type="text"
          />
        </div>
        <div className="field-row">
          <span>birthday</span>
          <input
            ref={register}
            name="birthday"
            placeholder={`birthday`}
            type="date"
          />
        </div>
        <div className="field-row">
          <span>Memo</span>
          <textarea
            ref={register}
            name="memo"
            placeholder={i18n.memo}
          />
        </div>

        <button
          className="btn btn-yellow btn-circle btn-save"
          onClick={handleSubmit(onSubmit)} >
          <i className="fa fa-save fa-2x"></i>
        </button>
      </div>
    </div>
  )
}

export default UserBotCustomerInfoForm;
