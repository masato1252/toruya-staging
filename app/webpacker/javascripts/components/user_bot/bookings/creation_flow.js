"use strict";

import React, { useEffect, useState } from "react";
import FlowController from "shared/flow_controller";
import { GlobalProvider } from "context/user_bots/bookings/global_state"
import { compatRead } from "../../../libraries/compat_api";
import I18n from 'i18n-js/index.js.erb';

import ShopSelectionStep from "./shop_selection_step";
import MenuSelectionStep from "./menu_selection_step";
import PriceSetupStep from "./price_setup_step";
import NoteSetupStep from "./note_setup_step";
import ConfirmationStep from "./confirmation_step";
import FinalStep from "./final_step";

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
          setLoadError("Failed to load booking page creation form");
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
              <ShopSelectionStep />
              <MenuSelectionStep />
              <PriceSetupStep />
              <NoteSetupStep />
              <ConfirmationStep />
              <FinalStep />
            </FlowController>
          </GlobalProvider>
        </div>

        <div className="col-sm-6 px-0 hidden-xs preview-view"></div>
      </div>
    </div>
  )

}

export default CreationFlow;
