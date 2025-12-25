"use strict";
import React, { useEffect, useState } from "react";

const ChargeFailedModal = (props) => {
  const [errorMessage, setErrorMessage] = useState(props.errorMessage || null);

  useEffect(() => {
    // モーダルが表示される際に、data属性からエラーメッセージを取得
    const modal = document.getElementById('charge-failed-modal');
    if (modal) {
      const updateErrorMessage = () => {
        const message = $(modal).data('error-message') || props.errorMessage;
        if (message) {
          setErrorMessage(message);
        }
      };
      
      // モーダル表示時にエラーメッセージを更新
      $(modal).on('show.bs.modal', updateErrorMessage);
      
      // props.errorMessageが変更された場合も更新
      if (props.errorMessage) {
        setErrorMessage(props.errorMessage);
      }
      
      return () => {
        $(modal).off('show.bs.modal', updateErrorMessage);
      };
    }
  }, [props.errorMessage]);

  const defaultMessage = props.i18n?.chargeFailedDesc1 || 
    props.i18n?.payment?.failed_desc1 ||
    "決済に失敗しました。";

  return (
    <div className="modal fade" id="charge-failed-modal" tabIndex="-1" role="dialog">
      <div className="modal-dialog" role="document">
        <div className="modal-content">
          <div className="modal-header">
            <button type="button" className="close" data-dismiss="modal" aria-label="Close">
              <span aria-hidden="true">×</span>
            </button>
            <h4 className="modal-title" id="myModalLabel">
              {/* {props.i18n?.chargeFailedTitle || props.i18n?.payment?.failed_title || "決済エラー"} */}
              決済エラー
            </h4>
          </div>
          <div className="modal-body">
            カード情報に問題があり決済(変更)できませんでした
            {/* <div style={{ color: '#9e2146', marginBottom: '15px', fontWeight: 'bold', padding: '10px', backgroundColor: '#fff5f5', borderRadius: '4px' }}>
              カード情報に問題があり決済(変更)できませんでした
            </div>
            {props.i18n?.chargeFailedDesc2 || props.i18n?.payment?.failed_desc2} */}
          </div>
          <div className="modal-footer">
            <div
             className={`btn btn-tarco`}
             onClick={() => { 
               setErrorMessage(null);
               $("#charge-failed-modal").data('error-message', null);
               $("#charge-failed-modal").modal("hide"); 
             }}
             >
             OK
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default ChargeFailedModal;
