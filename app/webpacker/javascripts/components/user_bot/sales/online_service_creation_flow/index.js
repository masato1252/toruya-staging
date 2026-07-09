"use strict";

import React, { useEffect, useState } from "react";
import FlowController from "shared/flow_controller";
import { GlobalProvider } from "./context/global_state"
import { compatRead } from "../../../../libraries/compat_api";
import I18n from 'i18n-js/index.js.erb';
import OnlineServiceSelectionStep from "./online_service_selection_step";
import SellingPriceStep from "./selling_price_step";
import SellingTimeStep from "./selling_time_step";
import SellingNumberStep from "./selling_number_step";
import HeaderTemplateSelectionStep from "./header_template_selection_step";
import HeaderSetupStep from "./header_setup_step";
import HeaderColorEditStep from "./header_color_edit_step";
import ContentSetupStep from "./content_setup_step";
import StaffSetupStep from "./staff_setup_step";
import ConfirmationStep from "./confirmation_step";
import FinalStep from "./final_step";

const SalesOnlineServiceCreationFlow = ({props: initialProps}) => {
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
          setLoadError("Failed to load online service sale creation form");
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
              <OnlineServiceSelectionStep key="online_service_selection_step" />
              <SellingPriceStep key="selling_price_step" />
              <SellingTimeStep key="selling_time_step" />
              <SellingNumberStep key="selling_number_step" />
              <HeaderTemplateSelectionStep key="header_template_selection_step" />
              <HeaderSetupStep key="header_setup_step" />
              <HeaderColorEditStep key="header_color_edit_step" />
              <ContentSetupStep key="content_setup_step" />
              <StaffSetupStep key="staff_setup_step" />
              <ConfirmationStep key="confirmation_step" />
              <FinalStep key="final_step" />
            </FlowController>
          </GlobalProvider>
        </div>

        <div className="col-sm-6 px-0 hidden-xs preview-view"></div>
      </div>
    </div>
  )
}

export default SalesOnlineServiceCreationFlow
