"use strict";

import React, { useEffect, useState } from "react";
import PropTypes from "prop-types";
import { compatRead } from "../../libraries/compat_api";
import PaymentModal from "./payment_modal";

/**
 * Renders paid LINE-notice approve CTA + Stripe modal when free trial is unavailable.
 * Free-trial approve is handled by compat_owner_show_shell activate_href.
 */
export default function CompatLineNoticeApprove({
  pageContextPath,
  stripeKey,
  businessOwnerId,
  lineNoticeRequestId,
  i18n,
}) {
  const [ctx, setCtx] = useState(null);

  useEffect(() => {
    let cancelled = false;
    compatRead(pageContextPath)
      .then((body) => {
        if (!cancelled) setCtx(body.data?.edit_form || null);
      })
      .catch(() => {
        if (!cancelled) setCtx(null);
      });
    return () => {
      cancelled = true;
    };
  }, [pageContextPath]);

  if (!ctx?.can_approve || ctx.is_free_trial) return null;

  const approveUrl = ctx.approve_href;
  const chargeAmount = ctx.charge_amount || 275;

  return (
    <>
      <div className="centerize margin-around" style={{ paddingTop: 10 }}>
        <button
          type="button"
          id="approve-with-payment-btn"
          className="btn btn-yellow btn-lg"
          style={{ padding: "12px 40px", fontSize: 18, borderRadius: 6 }}
          onClick={() => {
            window.dispatchEvent(new Event("openLineNoticePaymentModal"));
          }}
        >
          {i18n.paidApprove || "料金を支払って承認する"}
        </button>
      </div>
      <PaymentModal
        props={{
          lineNoticeRequestId,
          businessOwnerId,
          chargeAmount,
          stripeKey,
          approveUrl,
          i18n: {
            modalTitle: i18n.modalTitle,
            chargeAmountLabel: i18n.chargeAmountLabel,
            cardNumberLabel: i18n.cardNumberLabel,
            submitButton: i18n.submitButton,
          },
        }}
      />
    </>
  );
}

CompatLineNoticeApprove.propTypes = {
  pageContextPath: PropTypes.string.isRequired,
  stripeKey: PropTypes.string,
  businessOwnerId: PropTypes.oneOfType([PropTypes.string, PropTypes.number]).isRequired,
  lineNoticeRequestId: PropTypes.oneOfType([PropTypes.string, PropTypes.number]).isRequired,
  i18n: PropTypes.object,
};
