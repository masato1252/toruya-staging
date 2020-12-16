import React from "react";
import { Field } from "react-final-form";
import _ from "lodash";
import { sortableHandle } from "react-sortable-hoc";

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

const SelectOptions = ({ options }) => {
  return <>
    {options.map(option => <option key={option.value} value={option.value}>{option.label}</option>)}
  </>
}

const CiricleButtonWithWord = ({onHandle, icon, word}) => (
  <button
    className="btn btn-yellow btn-circle btn-save btn-tweak btn-with-word"
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

const BookingPageUrlCopyBtn = ({booking_page_url}) => {
  return (
    <button
      className="btn btn-tarco"
      data-controller="clipboard"
      data-action="click->clipboard#copy"
      data-clipboard-text={booking_page_url}
      data-clipboard-popup-text={`${I18n.t("common.copied")}`}>
      {I18n.t("action.copy_code")}
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
  CiricleButtonWithWord,
  BookingOptionElement,
  BookingPageUrlCopyBtn,
  BookingPageButtonCopyBtn,
};
