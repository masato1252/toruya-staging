import React, { useEffect, useState } from "react";
import FlowController from "shared/flow_controller";
import { GlobalProvider, useGlobalContext } from "./context/global_state"
import { compatRead } from "../../../../libraries/compat_api";
import I18n from 'i18n-js/index.js.erb';

import GoalSelectionStep from "./goal_selection_step"
import SolutionStep from "./solution_step"
import ExternalPurchaseUrlStep from "./external_purchase_url_step"
import NameStep from "./name_step"
import BundledItemsStep from "./bundled_items_step"
import BundledItemsEndTimeStep from "./bundled_items_end_time_step"
import EndtimeStep from "./endtime_step"
import UpsellStep from "./upsell_step"
import ConfirmationStep from "./confirmation_step"
import FinalStep from "./final_step"

const GoalFlowDispatcher = ({}) => {
  const { selected_goal } = useGlobalContext()

  switch (selected_goal) {
    case 'collection':
    case 'free_lesson':
    case 'paid_lesson':
    case 'ebook':
      return (
        <FlowController new_version={true}>
          <SolutionStep key="solution_step" />
          <NameStep key="name_step" />
          <EndtimeStep key="endtime_step" />
          <UpsellStep key="upsell_step" />
          <ConfirmationStep key="confirmation_step" />
          <FinalStep key="final_step" />
        </FlowController>
      )
    case 'free_course':
      return (
        <FlowController new_version={true}>
          <NameStep key="name_step" />
          <EndtimeStep key="endtime_step" />
          <FinalStep key="final_step" />
        </FlowController>
      )
    case 'course':
      return (
        <FlowController new_version={true}>
          <NameStep key="name_step" />
          <EndtimeStep key="endtime_step" />
          <FinalStep key="final_step" />
        </FlowController>
      )
    case 'bundler':
      return (
        <FlowController new_version={true}>
          <NameStep key="name_step" />
          <BundledItemsStep key="bundled_items_step" />
          <BundledItemsEndTimeStep key="bundled_items_end_time_step" />
          <FinalStep key="final_step" />
        </FlowController>
      )
    case 'membership':
      return (
        <FlowController new_version={true}>
          <NameStep key="name_step" />
          <FinalStep key="final_step" />
        </FlowController>
      )
    case 'external':
      return (
        <FlowController new_version={true}>
          <SolutionStep key="solution_step" />
          <ExternalPurchaseUrlStep key="external_purchase_url_step" />
          <NameStep key="name_step" />
          <EndtimeStep key="endtime_step" />
          <UpsellStep key="upsell_step" />
          <ConfirmationStep key="confirmation_step" />
          <FinalStep key="final_step" />
        </FlowController>
      )
    default:
      return <GoalSelectionStep key="goal_selection_step" />
  }
}

const CreationFlow = ({props: initialProps}) => {
  const [readyProps, setReadyProps] = useState(
    initialProps.pageContextPath ? null : initialProps,
  );
  const [loadError, setLoadError] = useState(null);

  useEffect(() => {
    if (!initialProps.pageContextPath) return undefined;

    let cancelled = false;
    compatRead(initialProps.pageContextPath)
      .then((body) => {
        if (cancelled) return;
        const form = body.data?.edit_form || body.data;
        if (!form) {
          setLoadError("Failed to load service creation form");
          return;
        }
        setReadyProps({ ...initialProps, ...form });
      })
      .catch((err) => {
        if (!cancelled) setLoadError(err.message);
      });

    return () => {
      cancelled = true;
    };
  }, [initialProps]);

  const props = readyProps;

  if (loadError) return <p className="danger">{loadError}</p>;
  if (!props) return <p>{I18n.t("common.processing")}</p>;

  return (
    <div className="container-fluid">
      <div className="row">
        <div className="col-sm-6 px-0 settings-view">
          <GlobalProvider props={props}>
            <GoalFlowDispatcher />
          </GlobalProvider>
        </div>

        <div className="col-sm-6 px-0 hidden-xs preview-view"></div>
      </div>
    </div>
  )
}

export default CreationFlow;