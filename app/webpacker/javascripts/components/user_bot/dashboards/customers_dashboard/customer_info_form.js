"use strict"

import React, { useEffect, useState } from "react";
import { useForm, useFieldArray } from "react-hook-form";
import { useHistory } from "react-router-dom";
import _ from "lodash";
import Popup from 'reactjs-popup';

import { useGlobalContext } from "context/user_bots/customers_dashboard/global_state";
import { BottomNavigationBar, TopNavigationBar, SelectOptions } from "shared/components"
import { CustomerServices } from "user_bot/api"
import useAddress from "libraries/use_address";
import ProcessingBar from "shared/processing_bar.js"
import EditTagsInput from "user_bot/services/episodes/shared/edit_tags_input";
import { TagsInput } from "shared/components";

const TopBar = () => {
  const { dispatch, props, selected_customer } = useGlobalContext()

  return (
    <TopNavigationBar
      leading={
        <a onClick={() => {
          if (selected_customer.id) {
            dispatch({type: "CHANGE_VIEW", payload: { view: "customer_info_view" }})
          }
          else {
            dispatch({type: "CHANGE_VIEW", payload: { view: "customers_list" }})
          }
        }}>
          <i className="fa fa-angle-left fa-2x"></i>
        </a>
      }
      title={props.i18n.form_title}
    />
  )
}

const BottomBar = ({handleSubmit, onSubmit}) => {
  const { selected_customer, props, deleteCustomer } = useGlobalContext()
  let history = useHistory();

  return (
    <BottomNavigationBar klassName="centerize">
      {selected_customer && (
        <Popup
          modal
          trigger={
            <button className="btn btn-orange btn-circle btn-delete btn-tweak btn-with-word">
              <i className="fa fa-trash fa-2x" aria-hidden="true"></i>
              <div className="word">{I18n.t("action.delete")}</div>
            </button>
          }>
            {close => (
              <div>
                <div className="modal-body centerize">
                  <div className="margin-around">
                    {I18n.t("user_bot.dashboards.customer.delete_confirmation_message")}
                  </div>
                </div>
                <div className="modal-footer flex justify-between">
                  <button
                    className="btn btn-orange"
                    onClick={() => {
                      deleteCustomer(selected_customer.id)
                      history.goBack()
                    }}>
                    {I18n.t("action.delete2")}
                  </button>
                  <button
                    className="btn btn-tarco"
                    onClick={close}>
                    {I18n.t("action.cancel")}
                  </button>
                </div>
              </div>
            )}
        </Popup>
      )}
      <span>{selected_customer?.id ? props.i18n.updated_date : props.i18n.unsave } {selected_customer.lastUpdatedAt}</span>

      <button
        className="btn btn-yellow btn-circle btn-save btn-with-word btn-tweak"
        onClick={handleSubmit(onSubmit)} >
        <i className="fa fa-save fa-2x"></i>
        <div className="word">{I18n.t("action.save")}</div>
      </button>
    </BottomNavigationBar>
  )
}

const UserBotCustomerInfoForm = () => {
  const { selected_customer, props, selectCustomer } = useGlobalContext()
  const { i18n } = props
  const [similarCustomers, setSimilarCustomers] = useState([])
  let history = useHistory();

  const [tags, setTags] = useState((selected_customer.tags || []).map((tag) => ({
    id: tag,
    text: tag,
    className: "tag"
  })) || [])

  const { register, watch, setValue, control, handleSubmit, formState } = useForm({
    defaultValues: {
      id: selected_customer.id,
      last_name: selected_customer.lastName,
      first_name: selected_customer.firstName,
      phonetic_last_name: selected_customer.phoneticLastName,
      phonetic_first_name: selected_customer.phoneticFirstName,
      contact_group_id: selected_customer.contactGroupId,
      rank_id: selected_customer.rankId || props.ranks[0].value,
      address_details: _.merge(selected_customer.addressDetails, { zip_code: selected_customer.addressDetails?.zipCode }),
      phone_numbers_details: selected_customer.phoneNumbersDetails || [],
      emails_details: selected_customer.emailsDetails || [],
      custom_id: selected_customer.customId,
      birthday: selected_customer.birthday,
      memo: selected_customer.memo,
    }
  });

  const { isSubmitting } = formState;
  const address = useAddress(watch("address_details[zip_code]"))
  const firstNameWatched = watch("first_name")
  const lastNameWatched = watch("last_name")

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

  const find_duplicate_customers = async () => {
    setSimilarCustomers([])
    const [error, response] = await CustomerServices.find_duplicate_customers({ business_owner_id: props.business_owner_id, last_name: lastNameWatched, first_name: firstNameWatched })

    setSimilarCustomers(response.data.customers)
  }

  useEffect(() => {
    if (!selected_customer?.id && firstNameWatched && lastNameWatched) {
      find_duplicate_customers()
    }
  }, [firstNameWatched, lastNameWatched] )

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

    [error, response] = await CustomerServices.save({ business_owner_id: props.business_owner_id, data: { ...data, tags } })

    window.location = response.data.redirect_to
  }

  return (
    <div className="customer-view form">
      <ProcessingBar processing={isSubmitting} />
      <TopBar />
      <input ref={register} name="id" type="hidden" />

      <div className="customer-edit">
        {
          !selected_customer.id && (
            <div className="field-row">
              <span className="warning">
                {I18n.t("common.hint")}: {I18n.t("user_bot.dashboards.customer.create_customer_manually_notice")}
              </span>
            </div>
          )
        }
        <div className="field-row" >
          <span>{i18n.group}</span>
          <select name="contact_group_id" ref={register({ required: true })}>
            <option value="">{i18n.group_blank_option}</option>
            <SelectOptions options={props.contact_groups} />
          </select>
        </div>
        <div className="field-row" >
          <span>{i18n.level_label}</span>
          <select name="rank_id" ref={register({ required: true })}>
            <SelectOptions options={props.ranks} />
          </select>
        </div>

        <div className="field-header">{i18n.name}</div>
        <div className="field-row" >
          <span>{i18n.last_name}</span>
          <span>
            <input
              ref={register({ required: true })}
              name="last_name"
              placeholder={i18n.last_name}
              type="text"
            />
          </span>
        </div>
        <div className="field-row" >
          <span>{i18n.first_name}</span>
          <span>
            <input
              ref={register({ required: true })}
              name="first_name"
              placeholder={i18n.first_name}
              type="text"
            />
          </span>
        </div>
        {similarCustomers.length > 0 && (
          <div className="field-row similar-customers-warnings" >
            <h3>There are similar customers, Are they the same customer you try to create? If not, please ignore them.</h3>
            {similarCustomers.map((similarCustomer) => {
              return (
                <div key={similarCustomer.id} className="warning" onClick={() => {
                  selectCustomer(similarCustomer)
                  history.push(Routes.lines_user_bot_customers_path({customer_id: similarCustomer.id, user_id: props?.shop?.user_id}));
                }}>
                  {similarCustomer.lastName} { similarCustomer.firstName } { similarCustomer.simpleAddress }
                </div>
              )
            })}
          </div>
        )}
        {props.support_feature_flags.support_phonetic_name && (
          <>
            <div className="field-row" >
              <span>{i18n.phonetic_last_name}</span>
              <span>
                <input
                  ref={register}
                  name="phonetic_last_name"
                  placeholder={i18n.phonetic_last_name}
                  type="text"
                />
              </span>
            </div>
            <div className="field-row" >
              <span>{i18n.phonetic_first_name}</span>
              <span>
                <input
                  ref={register}
                  name="phonetic_first_name"
                  placeholder={i18n.phonetic_first_name}
                    type="text"
                />
              </span>
            </div>
          </>
        )}

        <div className="field-header">{i18n.address}</div>
        <div className="field-row" >
          <span>{i18n.zip_code}</span>
          <input
            ref={register}
            name="address_details[zip_code]"
            placeholder="1234567"
            type="tel"
          />
        </div>
        <div className="field-row">
          <span>{i18n.region}</span>
          <input
            ref={register}
            name="address_details[region]"
            placeholder={i18n.region}
            type="text"
          />
        </div>
        <div className="field-row">
          <span>{i18n.city}</span>
          <input
            ref={register}
            name="address_details[city]"
            placeholder={i18n.city}
            type="text"
          />
        </div>
        <div className="field-row">
          <span>{i18n.address1}</span>
          <input
            ref={register}
            name="address_details[street1]"
            placeholder={i18n.address1}
            type="text"
          />
        </div>
        <div className="field-row">
          <span>{i18n.address2}</span>
          <input
            ref={register}
            name="address_details[street2]"
            placeholder={i18n.address2}
            type="text"
          />
        </div>

        <div className="field-header">{i18n.phone_number}</div>
        {phone_number_fields.fields.map((field, index) => (
          <div key={field.id} className="field-row">
            <select name={`phone_numbers_details[${index}].type`} ref={register({})} defaultValue={field.type}>
              <SelectOptions options={itemOptions(phone_number_fields.fields)} />
            </select>

            <input
              type="tel"
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

        <div className="field-header">{i18n.email}</div>
        {email_fields.fields.map((field, index) => (
          <div key={field.id} className="field-row">
            <select name={`emails_details[${index}].type`} ref={register({})} defaultValue={field.type}>
              <SelectOptions options={itemOptions(email_fields.fields)} />
            </select>

            <input
              type="email"
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

        <div className="field-header">{i18n.others}</div>
        <div className="field-row">
          <span>{i18n.customer_id}</span>
          <input
            ref={register}
            name="custom_id"
            placeholder={i18n.customer_id}
            type="text"
          />
        </div>
        <div className="field-row">
          <span>{i18n.birthday}</span>
          <input
            ref={register}
            name="birthday"
            placeholder={i18n.birthday}
            type="date"
          />
        </div>
        <div className="field-row">
          <span>{I18n.t("user_bot.dashboards.settings.membership.episodes.tag_input_placeholder")}</span>
          <TagsInput
            suggestions={props.customer_tags.map((tag) => ({
              id: tag,
              text: tag,
              className: "tag"
            }))}
            tags={tags}
            setTags={setTags}
          />
        </div>
        <div className="field-row">
          <span>{i18n.memo}</span>
          <textarea
            ref={register}
            name="memo"
            placeholder={i18n.memo}
            rows="4"
            colos="40"
          />
        </div>
      </div>

      <BottomBar
        handleSubmit={handleSubmit}
        onSubmit={onSubmit}
      />
    </div>
  )
}

export default UserBotCustomerInfoForm;
