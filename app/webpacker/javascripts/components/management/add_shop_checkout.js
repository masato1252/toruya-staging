"use strict";

import React, { useState } from "react";
import { loadStripe } from "@stripe/stripe-js";
import StripeCheckoutForm from "shared/stripe_checkout_form";
import ProcessingBar from "shared/processing_bar";

const AddShopCheckout = ({ props }) => {
  const [processing, setProcessing] = useState(false);
  const [errorMessage, setErrorMessage] = useState(null);
  const fallbackModalId = props.fallbackModalId || "addShopCardReentryModal";

  const csrfToken = () =>
    document.querySelector('meta[name="csrf-token"]')?.getAttribute("content");

  const submitPayment = async (payload) => {
    setProcessing(true);
    setErrorMessage(null);

    const response = await fetch(props.paymentPath, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Accept: "application/json",
        "X-CSRF-Token": csrfToken(),
      },
      body: JSON.stringify(payload),
    });

    setProcessing(false);

    if (response.ok) {
      const data = await response.json();
      window.location.href = data.redirect_path;
      return;
    }

    const data = await response.json();

    if (data.client_secret) {
      const stripe = await loadStripe(props.stripeKey);
      const result = await stripe.confirmCardPayment(data.client_secret);

      if (result.error) {
        setErrorMessage(result.error.message);
        return;
      }

      await submitPayment({
        payment_intent_id: result.paymentIntent.id,
      });
      return;
    }

    const failedMessage = data.message || props.i18n.chargeFailed;
    const isSavedCardFirstAttempt = props.useSavedCard && !payload.token && !payload.payment_intent_id;

    if (isSavedCardFirstAttempt) {
      openFallbackModal();
      return;
    }

    setErrorMessage(failedMessage);
  };

  const openFallbackModal = () => {
    if (props.sourceModalId) {
      $(`#${props.sourceModalId}`).modal("hide");
    }
    $(`#${fallbackModalId}`).modal("show");
  };

  const handlePrimaryAction = async () => {
    if (props.forceCardEntry) {
      return;
    }

    if (props.useSavedCard) {
      await submitPayment({});
      return;
    }

    openFallbackModal();
  };

  return (
    <div className="add-shop-checkout-action">
      <ProcessingBar processing={processing} processingMessage={props.processingMessage} />
      {errorMessage && <div className="alert alert-danger">{errorMessage}</div>}

      {props.forceCardEntry ? (
        <StripeCheckoutForm
          stripe_key={props.stripeKey}
          header={props.i18n.fallbackHeader || props.i18n.header}
          desc={props.i18n.fallbackDesc || props.i18n.desc}
          pay_btn={props.i18n.payBtnText}
          pay_btn_class="BTNtarco"
          details_desc={props.detailsDesc}
          handleToken={async (paymentMethodId) => submitPayment({ token: paymentMethodId })}
          handleFailure={(error) => setErrorMessage(error.message)}
        />
      ) : (
        <div className="centerize">
          <button type="button" className="btn btn-yellow" onClick={handlePrimaryAction} disabled={processing}>
            {processing ? (
              <>
                <i className="fa fa-spinner fa-spin fa-fw" aria-hidden="true"></i>
                {props.i18n.processing || props.processingMessage}
              </>
            ) : (
              props.i18n.payBtnText
            )}
          </button>
        </div>
      )}
    </div>
  );
};

export default AddShopCheckout;
