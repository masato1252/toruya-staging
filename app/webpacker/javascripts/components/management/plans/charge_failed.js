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
              {props.i18n?.chargeFailedTitle || props.i18n?.payment?.failed_title || "決済エラー"}
            </h4>
          </div>
          <div className="modal-body">
            {errorMessage ? (
              <>
                <div style={{ color: '#9e2146', marginBottom: '15px', fontWeight: 'bold', padding: '10px', backgroundColor: '#fff5f5', borderRadius: '4px' }}>
                  決済に失敗しました
                </div>
                <div style={{ whiteSpace: 'pre-wrap', wordBreak: 'break-word', marginBottom: '15px', padding: '10px', backgroundColor: '#f9f9f9', borderRadius: '4px', fontSize: '14px' }}>
                  <strong>エラー詳細:</strong><br/>
                  {errorMessage}
                </div>
                <div style={{ fontSize: '13px', color: '#666' }}>
                  {props.i18n?.chargeFailedDesc2 || props.i18n?.payment?.failed_desc2 || "カード情報をご確認の上、もう一度お試しください。問題が解決しない場合は、カード会社またはサポートにお問い合わせください。"}
                </div>
              </>
            ) : (
              <div>
                カード情報に問題があり決済(変更)できませんでした
              </div>
            )}
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
