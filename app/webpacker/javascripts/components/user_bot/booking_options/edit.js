"use strict"

import React, { useState } from "react";
import { useForm } from "react-hook-form";
import { Editor } from 'react-draft-wysiwyg';
import { EditorState, ContentState, convertToRaw } from 'draft-js';
import draftToHtml from 'draftjs-to-html';
import htmlToDraft from 'html-to-draftjs';
import TextareaAutosize from 'react-autosize-textarea';

import { BottomNavigationBar, TopNavigationBar, CircleButtonWithWord, CheckboxSearchFields } from "shared/components"
import { BookingOptionServices } from "user_bot/api"
import MenuRestrictOrderField from "./menu_restrict_order_field";
import BookingStartAtField from "components/user_bot/booking_pages/booking_start_at_field";
import BookingEndAtField from "components/user_bot/booking_pages/booking_end_at_field";
import BookingPriceField from "./booking_price_field";
import ExistingMenuField from "components/user_bot/booking_options/existing_menu_field";
import { responseHandler } from "libraries/helper";

const BookingOptionEdit =({props}) => {
  const i18n = props.i18n;
  const [inputType, setInputType] = useState(() => {
    const content = props.booking_option[props.attribute];
    return content && content.match(/<[^>]*>/) ? 'editor' : 'simple';
  });

  const [editorState, setEditorState] = useState(() => {
    const content = props.booking_option[props.attribute];
    if (!content) {
      return EditorState.createEmpty();
    }
    const contentState = ContentState.createFromBlockArray(
      htmlToDraft(content).contentBlocks
    );
    return EditorState.createWithContent(contentState);
  });

  const [displayName, setDisplayName] = useState(() => {
    return props.booking_option.display_name?.replace(/<[^>]*>/g, '') || '';
  });

  const { register, watch, setValue, control, handleSubmit, formState } = useForm({
    defaultValues: {
      ...props.booking_option,
      menu_restrict_order: String(props.booking_option.menu_restrict_order),
      tax_include: String(props.booking_option.tax_include),
      menu_required_time: props.editing_menu?.required_time,
      menu_id: props.editing_menu?.menu_id
    }
  });

  const onSubmit = async (data) => {
    let error, response;

    if (props.attribute === "display_name" && inputType === 'editor') {
      const rawContentState = convertToRaw(editorState.getCurrentContent());
      const htmlContent = draftToHtml(rawContentState);
      data[props.attribute] = htmlContent;
    }
    else if (props.attribute === "display_name" && inputType === 'simple') {
      data[props.attribute] = displayName;
    }

    // Ensure booking_page_ids is always an array, even if it's undefined, null, or a single value
    if (!data.booking_page_ids) {
      data.booking_page_ids = [];
    } else if (!Array.isArray(data.booking_page_ids)) {
      data.booking_page_ids = [data.booking_page_ids];
    }

    [error, response] = await BookingOptionServices.update({
      booking_option_id: props.booking_option.id,
      data: _.assign( data, { attribute: props.attribute, business_owner_id: props.business_owner_id })
    })

    responseHandler(error, response)
  }

  const handleInputTypeChange = (type) => {
    setInputType(type);
    if (type === 'simple' && props.booking_option[props.attribute]) {
      const strippedContent = props.booking_option[props.attribute].replace(/<[^>]*>/g, '');
      setDisplayName(strippedContent);
    }
  };

  const renderCorrespondField = () => {
    switch(props.attribute) {
      case "name":
        return (
          <div className="field-row">
            <input ref={register({ required: true })} name="name" type="text" className="extend" />
          </div>
        )
      case "display_name":
        return (
          <>
            <div className="field-row flex-start">
              <label>
                <input
                  type="radio"
                  checked={inputType === 'simple'}
                  onChange={() => {
                    handleInputTypeChange('simple');
                    const strippedContent = props.booking_option.display_name?.replace(/<[^>]*>/g, '');
                    setDisplayName(strippedContent);
                  }}
                /> {I18n.t("settings.booking_option.form.simple_text")}
              </label>
              {inputType === 'simple' ? (
                <input
                  value={displayName}
                  onChange={(e) => setDisplayName(e.target.value)}
                  name="display_name"
                  type="text"
                  className="extend"
                />
              ) : null}
            </div>
            <div className="field-row flex-start">
              <label>
                <input
                  type="radio"
                  checked={inputType === 'editor'}
                  onChange={() => handleInputTypeChange('editor')}
                /> {I18n.t("settings.booking_option.form.rich_text")}
              </label>
            </div>
            {inputType === 'editor' ? (
              <div className="field-row">
                <Editor
                  editorState={editorState}
                  onEditorStateChange={setEditorState}
                  toolbar={{
                    options: ['inline', 'fontSize', 'colorPicker'],
                    inline: {
                      options: ['bold']
                    },
                    fontSize: {
                      options: [12, 14, 16, 18, 24]
                    },
                    colorPicker: {
                      colors: ['rgb(97,189,109)', 'rgb(26,188,156)', 'rgb(84,172,210)', 'rgb(44,130,201)',
                        'rgb(147,101,184)', 'rgb(71,85,119)', 'rgb(204,204,204)', 'rgb(65,168,95)', 'rgb(0,168,133)',
                        'rgb(61,142,185)', 'rgb(41,105,176)', 'rgb(85,57,130)', 'rgb(40,50,78)', 'rgb(0,0,0)',
                        'rgb(255,0,0)', 'rgb(255,153,0)', 'rgb(255,255,0)', 'rgb(0,255,0)',
                        'rgb(0,255,255)', 'rgb(0,0,255)', 'rgb(153,0,255)', 'rgb(255,0,255)',
                        'rgb(244,67,54)', 'rgb(233,30,99)', 'rgb(156,39,176)', 'rgb(103,58,183)',
                        'rgb(63,81,181)', 'rgb(33,150,243)', 'rgb(0,188,212)', 'rgb(0,150,136)',
                        'rgb(76,175,80)', 'rgb(139,195,74)', 'rgb(205,220,57)', 'rgb(255,235,59)',
                        'rgb(255,193,7)', 'rgb(255,152,0)', 'rgb(255,87,34)', 'rgb(121,85,72)']
                    }
                  }}
                  toolbarClassName="toolbarClassName"
                  wrapperClassName="wrapperClassName"
                  editorClassName="editorClassName"
                />
              </div>
            ) : null}
            <div className="field-row hint no-border"> {i18n.hint} </div>
          </>
        );
      case "menu_restrict_order":
        return <MenuRestrictOrderField i18n={i18n} register={register} />
      case "booking_page_ids":
        return (
          <CheckboxSearchFields
            setValue={setValue}
            watch={watch}
            register={register}
            field_name="booking_page_ids[]"
            options={props.booking_page_options}
            checked_option_ids={props.booking_page_ids}
            search_placeholder={I18n.t("settings.booking_page.form.search_placeholder")}
          />
        )
      case "price":
        return <BookingPriceField setValue={setValue} register={register} watch={watch} ticket_expire_date_desc_path={props.ticket_expire_date_desc_path}/>
      case "memo":
        return (
          <div className="field-row column-direction">
            <TextareaAutosize autoFocus={true} ref={register} name={props.attribute} placeholder={i18n.note_hint} style={{ minHeight: 20 }} rows="2" colos="40" className="extend" />
          </div>
        );
      case "menu_required_time":
        return (
          <div className="field-row flex-start">
            {props.editing_menu?.label}
            <input ref={register({ required: true })} name="menu_required_time" type="tel" />
            <input ref={register({ required: true })} name="menu_id" type="hidden" />
            {i18n.minute}
          </div>
        );
      case "new_pure_menu":
        return (
          <div>
            <h3 className="header centerize">{I18n.t("settings.booking_option.form.create_a_new_menu")}</h3>

            <div className="field-header">{I18n.t("user_bot.dashboards.booking_page_creation.what_is_menu_name")}</div>
            <input autoFocus={true} ref={register({ required: true })} name="new_menu_name" className="extend" type="text" />

            <div className="field-header">{I18n.t("user_bot.dashboards.booking_page_creation.what_is_menu_time")}</div>
            <input ref={register({ required: true })} name="new_menu_minutes" className="extend" type="tel" />

            <div className="field-header">{I18n.t("user_bot.dashboards.booking_page_creation.is_menu_online")}</div>
            <label className="field-row flex-start">
              <input name="new_menu_online_state" type="radio" value="true" ref={register({ required: true })} />
              {I18n.t(`user_bot.dashboards.booking_page_creation.menu_online`)}
            </label>
            <label className="field-row flex-start">
              <input name="new_menu_online_state" type="radio" value="false" ref={register({ required: true })} />
              {I18n.t(`user_bot.dashboards.booking_page_creation.menu_local`)}
            </label>
          </div>
        )
      case "new_menu":
        return (
          <div>
            <ExistingMenuField
              i18n={i18n} register={register} watch={watch} control={control}
              menu_group_options={props.menu_group_options}
              setValue={setValue}
            />
            <div className="margin-around centerize">
              <button type="button" className="btn btn-yellow" onClick={handleSubmit(onSubmit)} disabled={formState.isSubmitting}>
                {formState.isSubmitting ? (
                  <i className="fa fa-spinner fa-spin fa-fw fa-2x" aria-hidden="true"></i>
                ) : (
                  I18n.t("user_bot.dashboards.booking_options.form.add_this_new_menu")
                )}
              </button>
            </div>
            <br />
            <br />
            <div className="field-header">{I18n.t("user_bot.dashboards.booking_options.form.add_a_new_menu")}</div>
            <div className="margin-around centerize">
              <h3 className="centerize">{I18n.t("settings.booking_option.form.does_require_a_new_menu")}</h3>
              <a href={Routes.edit_lines_user_bot_booking_option_path(props.business_owner_id, props.booking_option.id, { attribute: "new_pure_menu" })} className="btn btn-orange">
                {I18n.t("settings.booking_option.form.create_a_new_menu")}
              </a>
            </div>
          </div>
        )
      case "start_at":
        return <BookingStartAtField i18n={i18n} register={register} watch={watch} control={control} />
      case "end_at":
        return <BookingEndAtField i18n={i18n} register={register} watch={watch} control={control} />
    }
  }

  const isSubmitDisabled = () => {
    return formState.isSubmitting
  }

  return (
    <div className="form with-top-bar">
      <TopNavigationBar
        leading={
          <a href={Routes.lines_user_bot_booking_option_path(props.business_owner_id, props.booking_option.id)}>
            <i className="fa fa-angle-left fa-2x"></i>
          </a>
        }
        title={i18n.top_bar_header || i18n.page_title}
      />
      <div className="field-header">{i18n.page_title}</div>
      {renderCorrespondField()}
      <BottomNavigationBar klassName="centerize">
        <span></span>
        <CircleButtonWithWord
          disabled={isSubmitDisabled()}
          onHandle={handleSubmit(onSubmit)}
          icon={formState.isSubmitting ? <i className="fa fa-spinner fa-spin fa-2x"></i> : <i className="fa fa-save fa-2x"></i>}
          word={i18n.save}
        />
      </BottomNavigationBar>
    </div>
  )
}

export default BookingOptionEdit;
