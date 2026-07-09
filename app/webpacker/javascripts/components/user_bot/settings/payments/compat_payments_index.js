import React from "react";
import PropTypes from "prop-types";
import CompatOwnerShowShell from "../../shared/compat_owner_show_shell";

function buildReceiptHref({ businessOwnerId, encryptedOwnerId, chargeId, chargeType }) {
  const params = new URLSearchParams({ encrypted_user_id: encryptedOwnerId });
  if (chargeType === "line_notice_charge") {
    params.set("type", chargeType);
  }
  return `/lines/user_bot/owner/${businessOwnerId}/settings/payments/${chargeId}/receipt.pdf?${params.toString()}`;
}

function injectReceiptLinks(vm, { businessOwnerId, encryptedOwnerId, receiptLinkLabel }) {
  if (!vm?.field_groups?.length) return vm;

  const fieldGroups = vm.field_groups.map((group) => ({
    ...group,
    rows: (group.rows || []).map((row) => {
      if (row.header !== "charge_receipt" || !row.meta?.charge_id) return row;
      return {
        ...row,
        href: buildReceiptHref({
          businessOwnerId,
          encryptedOwnerId,
          chargeId: row.meta.charge_id,
          chargeType: row.meta.charge_type,
        }),
        link_title: receiptLinkLabel,
        row_display: "value",
      };
    }),
  }));

  return { ...vm, field_groups: fieldGroups };
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
  const postProcessVm = React.useCallback(
    (vm) =>
      injectReceiptLinks(vm, {
        businessOwnerId,
        encryptedOwnerId,
        receiptLinkLabel,
      }),
    [businessOwnerId, encryptedOwnerId, receiptLinkLabel],
  );

  return (
    <CompatOwnerShowShell
      pageContextPath={pageContextPath}
      groupLabels={groupLabels}
      rowLabels={rowLabels}
      actionLabels={actionLabels}
      postProcessVm={postProcessVm}
    />
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
