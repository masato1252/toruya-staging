"use strict";

import React, { useState, useRef } from "react";

// メールアドレスの簡易バリデーション
const isValidEmail = (email) => {
  if (!email || !email.trim()) return false;
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email.trim());
};

const CurrentCustomerInfo = ({booking_reservation_form_values, i18n, isCustomerTrusted, not_me_callback, set_booking_reservation_form_values}) => {
  const { customer_last_name, customer_first_name, found_customer, customer_email } = booking_reservation_form_values;
  const { simple_address, last_name, first_name } = booking_reservation_form_values.customer_info;
  const { not_me, edit_info, of, sir, thanks_for_come_back } = i18n

  // メール入力欄のタッチ状態（バリデーションエラー表示用）
  const [emailTouched, setEmailTouched] = useState(false);

  // 初回マウント時にメールが未把握だったかを記録（入力中に入力欄が消えないように）
  const needsEmailInput = useRef(!customer_email || !customer_email.trim());

  if (!found_customer) return <></>;

  if (found_customer) {
    return (
      <div className="customer-found">
        <div>
          {thanks_for_come_back}
        </div>
        <div>
          {simple_address && simple_address.trim().length > 0 && (
            <div className="simple-address">
              {simple_address}{simple_address && of}
            </div>
          )}
          <div className="customer-full-name">
            {customer_last_name || last_name} {customer_first_name || first_name} {sir}
          </div>
        </div>

        {/* メールアドレスが未把握の場合、入力欄を表示 */}
        {needsEmailInput.current && (
          <div style={{ marginTop: '16px', padding: '16px', backgroundColor: '#fff9e6', border: '1px solid #f0d860', borderRadius: '8px' }}>
            <div style={{ marginBottom: '8px', fontSize: '14px', color: '#666' }}>
              メールアドレスを入力してください。
            </div>
            <input
              type="email"
              className="form-control"
              value={customer_email || ""}
              onChange={(e) => {
                const value = e.target.value;
                set_booking_reservation_form_values(prev => ({
                  ...prev,
                  customer_email: value
                }));
              }}
              onBlur={() => setEmailTouched(true)}
              placeholder="example@example.com"
              style={{ fontSize: '16px' }}
            />
            {emailTouched && customer_email && !isValidEmail(customer_email) && (
              <div style={{ color: '#d9534f', fontSize: '12px', marginTop: '4px' }}>
                正しいメールアドレスの形式で入力してください
              </div>
            )}
          </div>
        )}

        <div className="edit-customer-info">
          <a href="#" onClick={() => $("#customer-info-modal").modal("show")}>{edit_info}</a>
        </div>
        <div className="not-me">
          <a href="#" onClick={not_me_callback}>
            {customer_last_name || last_name} {customer_first_name || first_name} {not_me}
          </a>
        </div>
      </div>
    )
  }
  else {
    return (
      <div className="customer-found">
        <div className="customer-full-name">
          {customer_last_name} {customer_first_name} {sir}
        </div>
      </div>
    )
  }
}

// isValidEmailをexportして他コンポーネントでも使えるように
export { isValidEmail };
export default CurrentCustomerInfo
