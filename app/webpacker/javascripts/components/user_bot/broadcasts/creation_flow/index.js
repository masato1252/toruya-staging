import React, { useEffect, useState } from "react";

import FlowController from "shared/flow_controller";
import { GlobalProvider } from "./context/global_state"
import { compatRead } from "../../../../libraries/compat_api";
import I18n from 'i18n-js/index.js.erb';

import FiltersSelectionStep from "./filters_selection_step"
import ProductSelectionStep from "./product_selection_step"
import ContentSetupStep from "./content_setup_step"
import ScheduleSetupStep from "./schedule_setup_step"
import ManualAssignmentStep from "./manual_assignment_step"

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
          setLoadError("Failed to load broadcast creation form");
          return;
        }
        setReadyProps({
          ...initialProps,
          ...form,
          support_feature_flags:
            initialProps.support_feature_flags || form.support_feature_flags || {},
          broadcast: form.broadcast || {},
        });
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
          {props.broadcast.query_type === "manual_assignment" ? (
            <GlobalProvider props={props}>
              <FlowController new_version={true}>
                <ManualAssignmentStep />
                <ContentSetupStep />
                <ScheduleSetupStep />
              </FlowController>
            </GlobalProvider>
          ) : (
            <GlobalProvider props={props}>
              <FlowController new_version={true}>
                <FiltersSelectionStep />
                <ProductSelectionStep />
                <ContentSetupStep />
                <ScheduleSetupStep />
              </FlowController>
            </GlobalProvider>
          )}
        </div>

        <div className="col-sm-6 px-0 hidden-xs preview-view"></div>
      </div>
    </div>
  )
}

export default CreationFlow;
