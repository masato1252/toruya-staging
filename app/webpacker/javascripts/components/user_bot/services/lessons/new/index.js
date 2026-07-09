import React, { useEffect, useState } from "react";
import FlowController from "shared/flow_controller";
import { GlobalProvider } from "./context/global_state"
import { compatRead } from "../../../../../libraries/compat_api";
import I18n from 'i18n-js/index.js.erb';

import NameStep from "./name_step"
import SolutionStep from "./solution_step"
import NoteStep from "./note_step"
import StartTimeStep from "./start_time_step"
import ConfirmationStep from "./confirmation_step"

const LessonNew = ({props: initialProps}) => {
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
          setLoadError("Failed to load lesson creation form");
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
            <FlowController new_version={true}>
              <NameStep />
              <SolutionStep />
              <NoteStep />
              <StartTimeStep />
              <ConfirmationStep />
            </FlowController>
          </GlobalProvider>
        </div>

        <div className="col-sm-6 px-0 hidden-xs preview-view"></div>
      </div>
    </div>
  )
}

export default LessonNew;
