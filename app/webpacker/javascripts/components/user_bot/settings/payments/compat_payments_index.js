import React from "react";
import PropTypes from "prop-types";
import { compatRead } from "../../../../libraries/compat_api";

function buildReceiptHref({ businessOwnerId, encryptedOwnerId, chargeId, chargeType }) {
  const params = new URLSearchParams({ encrypted_user_id: encryptedOwnerId });
  if (chargeType === "line_notice_charge") {
    params.set("type", chargeType);
  }
  return `/lines/user_bot/owner/${businessOwnerId}/settings/payments/${chargeId}/receipt.pdf?${params.toString()}`;
}

function groupHistoryRows(vm) {
  const rows = vm?.field_groups?.find((group) => group.id === "history")?.rows || [];
  const entries = [];
  for (let index = 0; index < rows.length; index += 4) {
    const [date, amount, plan, receipt] = rows.slice(index, index + 4);
    if (date?.header !== "charge_date" || receipt?.header !== "charge_receipt") continue;
    entries.push({ date, amount, plan, receipt });
  }
  return entries;
}

export default function CompatPaymentsIndex({
  pageContextPath,
  businessOwnerId,
  encryptedOwnerId,
  groupLabels,
  rowLabels,
  actionLabels,
  receiptLinkLabel,
}) {
  const [vm, setVm] = React.useState(null);
  const [error, setError] = React.useState(null);

  React.useEffect(() => {
    let cancelled = false;
    compatRead(pageContextPath)
      .then((response) => {
        if (!cancelled) setVm(response.data || null);
      })
      .catch((loadError) => {
        if (!cancelled) setError(loadError.message);
      });
    return () => {
      cancelled = true;
    };
  }, [pageContextPath]);

  if (error) return <p className="danger">{error}</p>;
  if (!vm) return <p>{actionLabels?.loading || "処理中..."}</p>;

  const entries = groupHistoryRows(vm);

  return (
    <table className="history">
      <thead>
        <tr>
          <th className="charge-date">{rowLabels?.charge_date}</th>
          <th className="charge-amount">{rowLabels?.charge_amount}</th>
          <th className="charge-plan">{rowLabels?.charge_plan}</th>
          <th className="charge-receipt">{rowLabels?.charge_receipt}</th>
        </tr>
      </thead>
      <tbody>
        {entries.map(({ date, amount, plan, receipt }) => {
          const chargeId = receipt.meta?.charge_id;
          const href = chargeId
            ? buildReceiptHref({
                businessOwnerId,
                encryptedOwnerId,
                chargeId,
                chargeType: receipt.meta.charge_type,
              })
            : null;
          return (
            <tr key={`${receipt.meta?.charge_type || "history"}-${chargeId || date.title}`}>
              <td>{date.title}</td>
              <td>{amount?.title}</td>
              <td>
                {plan?.title}
                {receipt.meta.period_label ? (
                  <div className="small text-muted">{receipt.meta.period_label}</div>
                ) : null}
                {receipt.meta.refunded ? " (返金)" : null}
              </td>
              <td>
                {href ? (
                  <a href={href} target="_blank" rel="noreferrer">
                    {receiptLinkLabel}
                  </a>
                ) : null}
              </td>
            </tr>
          );
        })}
      </tbody>
    </table>
  );
}

CompatPaymentsIndex.propTypes = {
  pageContextPath: PropTypes.string.isRequired,
  businessOwnerId: PropTypes.oneOfType([PropTypes.string, PropTypes.number]).isRequired,
  encryptedOwnerId: PropTypes.string.isRequired,
  groupLabels: PropTypes.object,
  rowLabels: PropTypes.object,
  actionLabels: PropTypes.object,
  receiptLinkLabel: PropTypes.string,
};
