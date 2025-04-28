import React, { useState, useEffect } from "react";
import I18n from 'i18n-js/index.js.erb'
import { Field } from "react-final-form";
import _ from "lodash";
import { sortableHandle } from "react-sortable-hoc";
import Routes from 'js-routes.js'
import { WithContext as ReactTags } from "react-tag-input";
import TimePicker from 'rc-time-picker';
import moment from 'moment';
import { Controller } from "react-hook-form";

const ErrorMessage = ({ error }) => (
  <p className="field-error-message" dangerouslySetInnerHTML={{ __html: error }} />
)

const Input = ({input, meta, className, ...rest}) => {
  const { error, touched } = meta;

  return (
    <input {...input} {...rest} className={`${error && touched ? "field-error" : ""} ${className}`} />
  )
}

const InputRow = ({ label, placeholder, type, input, requiredLabel, hint, before_hint, componentType, touched_required = true, meta: { error, touched }, ...rest }) => {
  const hasError = error && (touched_required ? touched : true);
  const Component = componentType || "input";

  return (
    <dl>
      {label ?
        <dt>
          {label} { requiredLabel ? <strong>{requiredLabel}</strong> : "" }
        </dt> : ""
      }
      <dd>
        { before_hint ? <span className="before-field-hint">{before_hint}</span> : ""}
        <Component {...input} {...rest} type={type} placeholder={placeholder || label} className={hasError ? "field-error" : ""} />
        { hint ? <span className="field-hint">{hint}</span> : ""}
        { hasError && <ErrorMessage error={error} />}
      </dd>
    </dl>
  );
}

const RadioRow = ({ input, children }) =>
  (
    <dl>
      <dd>
        <div className="radio">
          <Radio input={input}>
            {children}
          </Radio>
        </div>
      </dd>
    </dl>
  );

const Radio = ({ input, children }) =>
  (
    <label>
      <input type="radio" {...input} />
      {children}
    </label>
  );

const Error = ({ name, touched_required = true }) => (
  <Field name={name} subscription={{ error: true, touched: touched_required }}>
    {({ meta: { error, touched } }) =>
      error && (touched_required ? touched : true) ? <ErrorMessage error={error} /> : null
    }
  </Field>
);

const Condition = ({ when, is, children, is_not }) => (
  <Field name={when} subscription={{ value: true }}>
    {({ input: { value } }) => {
      let opposite = false
      let outcome

      if (is_not) {
        is = is_not;
        opposite = true
      }

      if (is === "present") {
        const isPresent = Array.isArray(value) ? value.length : !!value;

        outcome = isPresent ? children : null
      }
      else if (is === "blank") {
        const isPresent = Array.isArray(value) ? value.length : !!value;

        outcome = isPresent ? null : children
      }
      else if (Array.isArray(is)) {
        outcome = _.isEqual(_.sortBy(value), _.sortBy(is)) ? children : null
      }
      else if (typeof value === "boolean")
        outcome = String(value) === is ? children : null
      else if (is === "null") {

        outcome = is === "null" ? children : null
      }
      else {
        outcome = value === is ? children : null
      }

      if (opposite) {
        return outcome ? null : children
      }
      else {
        return outcome
      }
    }}
  </Field>
);

const DragHandle = sortableHandle(() => (
  <span className="drag-handler">
    <i className="fa fa-ellipsis-v"></i>
  </span>
));

const RequiredLabel = ({label, required_label}) => {
  return (
    <>
      <span>{label}</span>
      <span className="required-label">{required_label}</span>
    </>
  )
}

const DummyModalLink = ({ path, children, klass }) => {
  return (
    <div
      data-controller="modal"
      data-modal-target="#dummyModal"
      data-action="click->modal#popup"
      data-modal-path={path}
      className={klass}>
      {children}
    </div>
  )
}

const TopNavigationBar = ({leading, title, action, sticky, ...rest}) => {
  return (
    <div className={`top-navigation-bar ${sticky ? "react-sticky" : ""}`}>
      {leading}
      <span>{title}</span>
      {action || <i></i>}
    </div>
  )
}

const BottomNavigationBar = ({ klassName, children }) => {
  return (
    <div className={`bottom-navigation-bar ${klassName}`}>
      <div className="actions">
        {children}
      </div>
    </div>
  )
}

const InputWithEnter = React.forwardRef((props, ref) => {
  const { onHandleEnter, ...rest } = props;

  const handleKeyDown = (event) => {
    if (event.key === 'Enter') {
      onHandleEnter()
    }
  }

  return <input ref={ref} type="text" onKeyDown={handleKeyDown} {...rest} />
})

const NotificationMessages = ({notification_messages, dispatch}) => {
  return (
    <>
      {notification_messages.map((message, i) => {
        return (
          <div className="notification alert alert-info fade in" key={`notification-message-${i}`}>
            <span key={`message-${i}`} dangerouslySetInnerHTML={{ __html: message }} />
            <button className="close" onClick={() => dispatch({
              type: "REMOVE_NOTIFICATION",
              payload: {
                index: i
              }
            })}>x</button>
          </div>
        )
      })}
    </>
  )
}

const ChangeLogsNotifications = () => {
  return <div dangerouslySetInnerHTML={{ __html: I18n.t("user_bot.dashboards.change_logs.notification_message_html", { change_log_path: Routes.lines_user_bot_change_log_path() }) }} />
}

const SelectOptions = ({ options }) => {
  return <>
    {options.map(option => <option key={option.value} value={option.value}>{option.label}</option>)}
  </>
}

const CircleButtonWithWord = ({onHandle, icon, word, disabled, klassName}) => (
  <button
    disabled={disabled}
    className={klassName ? klassName : "btn btn-yellow btn-circle btn-save btn-tweak btn-with-word"}
    onClick={onHandle}>
    {icon}
    <div className="word">{word}</div>
  </button>
)

const BookingOptionElement = ({onClick, booking_option, i18n}) => (
  <div className="field-row with-next-arrow" onClick={onClick}>
    <div>
      <h3>{booking_option.name}</h3>
      <div className="desc">
        {i18n.booking_option_required_time}{booking_option.minutes}{i18n.minute}<br />
        {booking_option.price}
      </div>
    </div>
    <i className="fa fa-angle-right"></i>
  </div>
)

const UrlCopyInput = ({url}) => {
  return (
    <input
      type="text"
      readOnly
      className="extend"
      data-controller="clipboard"
      data-action="click->clipboard#copy"
      data-clipboard-text={url}
      data-clipboard-popup-text={`${I18n.t("common.copied")}`}
      value={url}
    />
  )
}

const UrlCopyBtn = ({url}) => {
  return (
    <button
      className="btn btn-tarco"
      data-controller="clipboard"
      data-a
      data-clipboard-text={url}
      data-clipboard-popup-text={`${I18n.t("common.copied")}`}>
      {I18n.t("action.copy_url2")}
    </button>
  )
}

const BookingPageButtonCopyBtn = ({booking_page_url}) => {
  return (
    <button
      className="btn btn-tarco"
      data-controller="clipboard"
      data-action="click->clipboard#copy"
      data-clipboard-text={`<a style="display: inline-block;background-color: #aecfc8;border: 1px solid #84b3aa;border-radius: 6px;-moz-border-radius: 6px;-webkit-border-radius: 6px;-o-border-radius: 6px;-ms-border-radius: 6px;line-height: 40px;color: #fff;font-size: 14px;font-weight: bold;text-decoration: none;padding: 0 10px;" target="_blank" href="${booking_page_url}">予約する</a>`}
      data-clipboard-popup-text={`${I18n.t("common.copied")}`}>
      {I18n.t("action.copy_code")}
    </button>
  )
}

const SubmitButton = ({handleSubmit, submitCallback, btnWord, disabled}) => {
  const [submitting, setSubmitting] = useState(false)

  return (
    <button
      type="submit"
      className="btn btn-yellow"
      disabled={disabled || submitting}
      onClick={async () => {
        if (disabled || submitting) return;
        setSubmitting(true)

        if (await handleSubmit()) {
          setSubmitting(false)
          if (submitCallback) {
            submitCallback()
          }
        } else  {
          setSubmitting(false)
        }
      }}>
        {submitting ? (
          <i className="fa fa-spinner fa-spin fa-fw fa-2x" aria-hidden="true"></i>
        ) : (
          btnWord
        )}
      </button>
  )
}

const DemoEditButton = ({demo, jump, jumpByKey}) => {
  if (!demo) return <></>

  return (
    <span className="btn btn-yellow edit-mark" onClick={jump || jumpByKey}>
      <i className="fa fa-pencil-alt"></i>{I18n.t("action.edit")}
    </span>
  )
}

const SwitchButton = ({checked, onChange, name, offWord, onWord, nosize}) => {
  return (
    <>
      <input
        id={name}
        type="checkbox"
        className="checkbox-button-box"
        checked={checked}
        onChange={onChange}
      />
      <label className={`checkbox-button-label ${nosize ? "nosize" : ""}`} htmlFor={name} data-before-content={offWord} data-after-content={onWord}></label>
    </>
  )
}

const EndOnDaysRadio = ({prefix, end_time, set_end_time_type, set_end_time_value }) => (
  <div className="margin-around">
    <label className="">
      <div>
        <input
          name={`${prefix}_end_type`} type="radio" value="end_on_days"
          checked={end_time.end_type === "end_on_days"}
          onChange={set_end_time_type}
        />
        {I18n.t("user_bot.dashboards.online_service_creation.expire_after_n_days")}
      </div>
      {end_time.end_type === "end_on_days" && (
        <>
          {I18n.t("user_bot.dashboards.online_service_creation.after_bought")}
          <input
            type="tel"
            value={end_time.end_on_days || ""}
            onChange={(event) => {
              set_end_time_value(event.target.value)
            }} />
          {I18n.t("user_bot.dashboards.online_service_creation.after_n_days")}
        </>
      )}
    </label>
  </div>
)

const EndOnMonthRadio = ({prefix, end_time, set_end_time_type, set_end_time_value }) => (
  <div className="margin-around">
    <label className="">
      <div>
        <input
          name={`${prefix}_end_type`} type="radio" value="end_on_months"
          checked={end_time.end_type === "end_on_months"}
          onChange={set_end_time_type}
        />
        {I18n.t("user_bot.dashboards.online_service_creation.expire_after_n_months")}
      </div>
      {end_time.end_type === "end_on_months" && (
        <>
          {I18n.t("user_bot.dashboards.online_service_creation.after_bought")}
          <input
            type="tel"
            value={end_time.end_on_months|| ""}
            onChange={(event) => {
              set_end_time_value(event.target.value)
            }}
          />
          {I18n.t("user_bot.dashboards.online_service_creation.after_n_months")}
        </>
      )}
    </label>
  </div>
)

const EndAtRadio = ({prefix, end_time, set_end_time_type, set_end_time_value }) => (
  <div className="margin-around">
    <label className="">
      <div>
        <input name={`${prefix}_end_type`} type="radio" value="end_at"
          checked={end_time.end_type === "end_at"}
          onChange={set_end_time_type}
        />
        {I18n.t("user_bot.dashboards.online_service_creation.expire_at")}
      </div>
      {end_time.end_type === "end_at" && (
        <input
          name="end_time_date_part"
          type="date"
          value={end_time.end_time_date_part || ""}
          onChange={(event) => {
            set_end_time_value(event.target.value)
          }}
        />
      )}
    </label>
  </div>
)

const NeverEndRadio = ({prefix, end_time, set_end_time_type }) => (
  <div className="margin-around">
    <label className="">
      <input name={`${prefix}_end_type`} type="radio" value="never"
        checked={end_time.end_type === "never"}
        onChange={set_end_time_type}
      />
      {I18n.t("user_bot.dashboards.online_service_creation.never_expire")}
    </label>
  </div>
)

const SubscriptionRadio = ({prefix, end_time, set_end_time_type }) => (
  <div className="margin-around">
    <label className="">
      <input name={`${prefix}_end_type`} type="radio" value="subscription"
        checked={end_time.end_type === "subscription"}
        onChange={set_end_time_type}
      />
      {I18n.t("user_bot.dashboards.online_service_creation.expire_by_subscription")}
    </label>
  </div>
)

const TicketPriceDesc = ({ amount, ticket_quota }) => {
  return <>{Math.trunc(amount / ticket_quota)} {I18n.t("common.unit")} X {ticket_quota} {I18n.t("common.times")}</>
}

const TicketOptionsFields = ({ setValue, watch, price, register, ticket_expire_date_desc_path }) => {
  useEffect(() => {
    if (watch("price_type") == "ticket" && (watch("ticket_quota") == '' || watch("ticket_quota") < 2 )) {
      setValue("ticket_quota", 2)
    }
  }, [watch("price_type")])

  return (
    <>
      <div className="field-row">
        <label>
          <input name="price_type" type="radio" value="regular" ref={register({ required: true })} />
          {I18n.t("common.regular_price")}
        </label>
      </div>
      <div className="field-row">
        <label>
          <input name="price_type" type="radio" value="ticket" ref={register({ required: true })} />
          {I18n.t("common.ticket")}
        </label>
      </div>
      {watch("price_type") == "ticket" && (
        <>
          <div className="field-header">{I18n.t("settings.booking_option.form.how_many_ticket_in_one_book")}</div>
          <div className="field-row">
            <div>
              <select name="ticket_quota" ref={register()}>
                {[2, 3, 4, 5, 6, 7, 8, 9, 10, 11,
                  12, 13, 14, 15, 16, 17, 18, 19, 20].map((num) => <option key={`quota-$${num}`} value={num}>{num}</option>)}
              </select> {I18n.t("common.times")}
              <div>
                <TicketPriceDesc amount={price} ticket_quota={watch("ticket_quota")} />
              </div>
            </div>
          </div>
          <div className="field-header">{I18n.t("settings.booking_option.form.when_ticket_expire")}</div>
          <div className="field-row">
            <span>
              {I18n.t("settings.booking_option.form.from_purchase")}
              <select name="ticket_expire_month" ref={register()}>
                {[1, 2, 3, 4, 5, 6].map((num) => <option key={`month-$${num}`} value={num}>{num}</option>)}
              </select>
              {I18n.t("settings.booking_option.form.after_month")}
              {watch("ticket_expire_month") == 6 && <>（{I18n.t("settings.booking_option.form.max_ticket_date")}）</>}
            </span>
          </div>
          <div className="field-row">
            <img src={ticket_expire_date_desc_path} className="w-full" />
          </div>
        </>
      )}
    </>
  )
}

const CheckboxSearchFields = ({ register, options, checked_option_ids, field_name, search_placeholder}) => {
  const [checkbox_options, setCheckboxOptions] = useState(options);
  const [query_text, setQueryText] = useState("");

  return (
    <>
      <div className="field-row">
        <input
          type="text"
          onChange={(event) => {
            setQueryText(event.target.value)
            let re = new RegExp(event.target.value, "gi");
            setCheckboxOptions(options.filter((option) => option.label.match(re) ))
          }}
          value={query_text}
          name="queryText"
          placeholder={search_placeholder}
        />
      </div>
      {checkbox_options.map((option, index) => {
        return (
          <div
            className="field-row flex-start dotdotdot"
            key={`option-${option.value}`}
          >
            <input
              type="checkbox"
              name={field_name}
              id={`option-${option.value}`}
              ref={register()}
              value={option.value}
              defaultChecked={checked_option_ids ? checked_option_ids.includes(option.value) : (options.length && index == 0)}
            />
            <label htmlFor={`option-${option.value}`}>{option.label}</label>
          </div>
        )
      })}
    </>
  )
}

const TagsInput = ({ suggestions, tags, setTags }) => {
  const handleDelete = (index) => {
    setTags(tags.filter((_, i) => i !== index));
  };

  const handleAddition = (tag) => {
    setTags((prevTags) => {
      return [...prevTags, tag];
    });
  };

  return (
    <div className="tags-input">
      <ReactTags
        autoFocus={false}
        tags={tags}
        inputFieldPosition="bottom"
        separators={[]}
        suggestions={suggestions}
        handleDelete={handleDelete}
        handleAddition={handleAddition}
        placeholder={I18n.t("common.press_enter_to_add_tag")}
        allowAdditionFromPaste
      />

      <button
        className="btn btn-yellow"
        onClick={() => {
        const inputElement = document.querySelector('.ReactTags__tagInputField');
        if (inputElement && inputElement.value) {
          const newTag = { id: inputElement.value, text: inputElement.value };
          handleAddition(newTag);
          inputElement.value = '';
        }
      }}>
        <i className="fa fa-plus"></i>
      </button>
    </div>
  )
}

const TimePickerController = ({name, control, defaultValue}) => {
  return (
    <Controller
      name={name}
      control={control}
      defaultValue={defaultValue}
      render={({ onChange, value }) => (
        <TimePicker
          showSecond={false}
          minuteStep={5}
          value={value ? moment(value, 'HH:mm') : null}
          defaultOpenValue={value ? moment(value, 'HH:mm') : moment().minutes(0)}
          onChange={(time) => onChange(time ? time.format('HH:mm') : null)}
          format="HH:mm"
          allowEmpty={false}
          addon={(panel) => (
            <button
              className="btn btn-primary"
              style={{ width: '100%', marginTop: '5px' }}
              onClick={() => panel.close()}
            >
              OK
            </button>
          )}
        />
      )}
    />
  )
}

const CustomTimePicker = ({value, onChange, name}) => {
  const defaultTimeValue = value ? moment(value, 'HH:mm', true) : moment().minutes(0);

  return (
    <TimePicker
      name={name}
      showSecond={false}
      minuteStep={5}
      allowEmpty={false}
      value={value ? moment(value, 'HH:mm') : null}
      defaultOpenValue={value ? moment(value, 'HH:mm') : moment().minutes(0)}
      onChange={(time) => onChange(time ? time.format('HH:mm') : null)}
      format="HH:mm"
      addon={(panel) => (
        <button
          className="btn btn-primary"
          style={{ width: '100%', marginTop: '5px' }}
          onClick={() => panel.close()}
        >
          OK
        </button>
      )}
    />
  )
}

const CustomerSelectionList = ({
  candidateCustomers,
  selectedCustomerIds,
  onCustomerToggle,
  customerStatusType
}) => {
  return (
    <div className="customer-selection-list p-6">
      {candidateCustomers && candidateCustomers.map((customer) => (
        <div className="flex justify-evenly items-center text-left" key={customer.id}>
          <div className="w-1-12 text-left">
            <label className="customer-checkbox">
              <input
                type="checkbox"
                checked={selectedCustomerIds.includes(customer.id)}
                onChange={() => onCustomerToggle(customer.id)}
              />
            </label>
          </div>
          <div className="w-7-12 text-left">{customer.name}</div>
          <div className={`w-4-12 text-white text-left reservation-state ${customer.state}`}>
            {I18n.t(`common.customer_status.${customerStatusType}.${customer.state}`)}
          </div>
        </div>
      ))}
    </div>
  );
};

export {
  Input,
  InputRow,
  RadioRow,
  Radio,
  Error,
  Condition,
  ErrorMessage,
  DragHandle,
  RequiredLabel,
  DummyModalLink,
  TopNavigationBar,
  BottomNavigationBar,
  InputWithEnter,
  NotificationMessages,
  SelectOptions,
  CircleButtonWithWord,
  BookingOptionElement,
  UrlCopyBtn,
  UrlCopyInput,
  BookingPageButtonCopyBtn,
  SubmitButton,
  DemoEditButton,
  SwitchButton,
  EndOnDaysRadio,
  EndOnMonthRadio,
  EndAtRadio,
  NeverEndRadio,
  SubscriptionRadio,
  ChangeLogsNotifications,
  TicketPriceDesc,
  TicketOptionsFields,
  CheckboxSearchFields,
  TagsInput,
  TimePickerController,
  CustomTimePicker,
  CustomerSelectionList
};
