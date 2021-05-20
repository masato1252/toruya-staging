import React, { useEffect } from "react";
import ReactSelect from "react-select";

import I18n from 'i18n-js/index.js.erb';
import { useGlobalContext } from "./context/global_state";
import FlowStepIndicator from "./flow_step_indicator";

const FroductSelectionStep = ({next, step, prev}) => {
  const { props, dispatch, query_type, selected_menu, selected_online_service } = useGlobalContext()

  useEffect(() => {
    if (query_type === "all") next()
  }, [])

  const renderProductDropDown = () => {
    switch (query_type) {
      case "menu":
        return (
          <>
            <ReactSelect
              className="text-left"
              placeholder={I18n.t("common.select_a_menu")}
              value={ _.isEmpty(selected_menu) ? "" : selected_menu}
              options={props.menus}
              onChange={
                (menu) => {
                  dispatch({
                    type: "SET_ATTRIBUTE",
                    payload: {
                      attribute: "selected_menu",
                      value: menu
                    }
                  })

                  dispatch({
                    type: "SET_ATTRIBUTE",
                    payload: {
                      attribute: "query",
                      value:  {
                        operator: "or",
                        filters: [
                          {
                            field: "menu_ids",
                            condition: "contains",
                            value: menu.value
                          },
                        ]
                      }
                    }
                  })
                }
              }
            />
          </>
        )
        break
      case "online_service":
        return (
          <>
            <div className="margin-around">
              <ReactSelect
                className="text-left"
                Value={selected_online_service ? { label: selected_online_service.name } : ""}
                defaultValue={selected_online_service ? { label: selected_online_service.name } : ""}
                placeholder={I18n.t("common.select_a_service")}
                options={props.online_services}
                onChange={
                  (online_service_option)=> {
                    dispatch({
                      type: "SET_ATTRIBUTE",
                      payload: {
                        attribute: "selected_online_service",
                        value: online_service_option.value
                      }
                    })

                    dispatch({
                      type: "SET_ATTRIBUTE",
                      payload: {
                        attribute: "query",
                        value:  {
                          operator: "or",
                          filters: [
                            {
                              field: "online_service_ids",
                              condition: "contains",
                              value: online_service_option.value.id
                            },
                          ]
                        }
                      }
                    })
                  }
                }
              />
            </div>
            {selected_online_service && (
              <div className="item-container">
                <div className="item-element">
                  <span>{I18n.t("common.content")}</span>
                  <span className="item-data">{selected_online_service?.solution}</span>
                </div>
                <div className="item-element">
                  <span>{I18n.t("user_bot.dashboards.sales.online_service_creation.service_start")}</span>
                  <span className="item-data">{selected_online_service?.start_time_text}</span>
                </div>
                <div className="item-element">
                  <span>{I18n.t("user_bot.dashboards.sales.online_service_creation.service_end")}</span>
                  <span className="item-data">{selected_online_service?.end_time_text}</span>
                </div>
              </div>
            )}
          </>
        )
        break
    }
  }

  return (
    <div className="form settings-flow centerize">
      <FlowStepIndicator step={step} />
      <h3 className="header centerize">
        {query_type === "menu" ? I18n.t("user_bot.dashboards.broadcast_creation.what_menu_do_you_want") : I18n.t("user_bot.dashboards.broadcast_creation.what_service_do_you_want")}
      </h3>
      {renderProductDropDown()}
      <div className="action-block">
        <button onClick={prev} className="btn btn-tarco">
          {I18n.t("action.prev_step")}
        </button>
        <button onClick={next} className="btn btn-yellow" disabled={!selected_online_service && !selected_menu}>
          {I18n.t("action.next_step")}
        </button>
      </div>
    </div>
  )
}

export default FroductSelectionStep;
