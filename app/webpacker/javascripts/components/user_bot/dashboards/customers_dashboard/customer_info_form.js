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
import { TagsInput } from "shared/components";
import { responseHandler } from "libraries/helper";

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

const BottomBar = ({handleSubmit, onSubmit, isSubmitting}) => {
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
        className="btn btn-yellow btn-circle btn-save btn-with-word btn-tweak btn-extend-right"
        onClick={handleSubmit(onSubmit)}
        disabled={isSubmitting} >
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
  const [isSubmitting, setIsSubmitting] = useState(false)
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

  const { isSubmitting: formStateIsSubmitting } = formState;
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

  // Ensure at least one empty phone number field if there are none
  useEffect(() => {
    if (phone_number_fields.fields.length === 0) {
      phone_number_fields.append({type: "mobile", value: ""})
    }
  }, [phone_number_fields.fields.length])

  // Ensure at least one empty email field if there are none
  useEffect(() => {
    if (email_fields.fields.length === 0) {
      email_fields.append({type: "mobile", value: ""})
    }
  }, [email_fields.fields.length])

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
    if (isSubmitting) return;
    setIsSubmitting(true);

    const [error, response] = await CustomerServices.save({ business_owner_id: props.business_owner_id, data: { ...data, tags } })
    responseHandler(error, response)
    setIsSubmitting(false);
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
                <a href={Routes.lines_user_bot_booking_pages_path(props.business_owner_id)} className="btn btn-tarco ml-2">
                  {I18n.t("user_bot.dashboards.customer.share_booking_page")}
                </a>
              </span>
            </div>
          )
        }
        {props.support_feature_flags.support_advance_customer_info && (
          <>
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
          </>
        )}

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

        <div className="field-header">{i18n.phone_number}</div>
        {phone_number_fields.fields.map((field, index) => (
          <div key={field.id} className="field-row">
            <span>{I18n.t("common.cellphone_number")}</span>
            <input
              type="hidden"
              name={`phone_numbers_details[${index}].type`}
              ref={register({})}
              value="mobile"
            />

            <input
              type="tel"
              name={`phone_numbers_details[${index}].value`}
              ref={register({
                pattern: /^[0-9]*$/
              })}
              defaultValue={field.value}
              className="full-width"
              pattern="[0-9]*"
              placeholder="00000000000"
              inputMode="numeric"
              onKeyPress={(e) => {
                const charCode = e.which ? e.which : e.keyCode;
                if (charCode < 48 || charCode > 57) {
                  e.preventDefault();
                }
              }}
            />
            {phone_number_fields.fields.length > 1 && (
              <button
                className="btn btn-orange"
                onClick={() => phone_number_fields.remove(index)}
              >
                <i className="fa fa-minus"></i>
              </button>
            )}
          </div>
        ))}

        <div className="field-header">{i18n.email}</div>
        {email_fields.fields.map((field, index) => (
          <div key={field.id} className="field-row">
            <span>{I18n.t("common.email")}</span>
            <input
              type="hidden"
              name={`emails_details[${index}].type`}
              ref={register({})}
              value="mobile"
            />

            <input
              type="email"
              name={`emails_details[${index}].value`}
              ref={register({})}
              defaultValue={field.value}
              className="full-width"
            />

            {email_fields.fields.length > 1 && (
              <button
                className="btn btn-orange"
                onClick={() => email_fields.remove(index)}
              >
                <i className="fa fa-minus"></i>
              </button>
            )}
          </div>
        ))}

        <div className="field-header">{i18n.others}</div>
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
        <div className="field-row">
          <span>{i18n.customer_id}</span>
          <input
            ref={register}
            name="custom_id"
            placeholder={i18n.customer_id}
            type="text"
          />
        </div>

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

      </div>

      <BottomBar
        handleSubmit={handleSubmit}
        onSubmit={onSubmit}
        isSubmitting={isSubmitting}
      />
    </div>
  )
}

export default UserBotCustomerInfoForm;
