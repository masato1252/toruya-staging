"use strict";

import React from "react";
import I18n from 'i18n-js/index.js.erb';

const UpgradeConfirmationModal = ({props, selectedPlan, rank, onConfirm, onCancel}) => {
  const [loading, setLoading] = React.useState(false);
  const [previewData, setPreviewData] = React.useState(null);

  React.useEffect(() => {
    if (selectedPlan && selectedPlan.key && rank !== undefined) {
      fetchUpgradePreview();
    } else {
      console.log("UpgradeConfirmationModal: Missing required data", { selectedPlan, rank });
    }
  }, [selectedPlan?.key, rank]);

  // const getSocialServiceUserId = () => {
  //   // URLパラメータから取得を試みる
  //   const urlParams = new URLSearchParams(window.location.search);
  //   const socialServiceUserId = urlParams.get('social_service_user_id');
  //   if (socialServiceUserId) {
  //     return socialServiceUserId;
  //   }
  //   // URLパスから取得を試みる（例: /lines/user_bot/owner/82/settings/profile/social_service_user_id/U5c9939915051dd21523d3e0bee5a2708）
  //   const pathMatch = window.location.pathname.match(/social_service_user_id\/([^\/\?]+)/);
  //   if (pathMatch) {
  //     return pathMatch[1];
  //   }
  //   return null;
  // };

  const fetchUpgradePreview = async () => {
    if (!selectedPlan || !selectedPlan.key || rank === undefined) {
      console.error("UpgradeConfirmationModal: Cannot fetch preview - missing data", { selectedPlan, rank });
      setPreviewData(null);
      return;
    }

    setLoading(true);
    try {
      // const socialServiceUserId = getSocialServiceUserId();
      let url = `/lines/user_bot/owner/${props.business_owner_id}/settings/payments/upgrade_preview?plan=${selectedPlan.key}&rank=${rank}`;
      // if (socialServiceUserId) {
      //   url += `&social_service_user_id=${socialServiceUserId}`;
      // }
      console.log("Fetching upgrade preview from:", url);
      
      const response = await fetch(url, {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
          "X-Requested-With": "XMLHttpRequest",
        },
        credentials: "same-origin"
      });

      console.log("Response status:", response.status);
      
      if (response.ok) {
        const data = await response.json();
        console.log("Preview data:", data);
        if (data.error) {
          console.error("API returned error:", data.error);
          setPreviewData(null);
        } else {
          setPreviewData(data);
        }
      } else {
        const errorData = await response.json().catch(() => ({ error: "Unknown error" }));
        console.error("Failed to fetch upgrade preview:", response.status, errorData);
        setPreviewData(null);
      }
    } catch (error) {
      console.error("Error fetching upgrade preview:", error);
      setPreviewData(null);
    } finally {
      setLoading(false);
    }
  };

  const handleConfirm = () => {
    if (onConfirm) {
      onConfirm();
    }
  };

  const handleCancel = () => {
    if (onCancel) {
      onCancel();
    }
  };

  // モーダルが表示された時にデータを取得
  React.useEffect(() => {
    const modal = document.getElementById('upgrade-confirmation-modal');
    if (modal) {
      const handleShow = () => {
        if (selectedPlan && selectedPlan.key && rank !== undefined) {
          fetchUpgradePreview();
        }
      };
      $(modal).on('shown.bs.modal', handleShow);
      return () => {
        $(modal).off('shown.bs.modal', handleShow);
      };
    }
  }, [selectedPlan?.key, rank]);

  return (
    <div className="modal fade" id="upgrade-confirmation-modal" tabIndex="-1" role="dialog">
      <div className="modal-dialog" role="document">
        <div className="modal-content">
          <div className="modal-header">
            <button type="button" className="close" data-dismiss="modal" aria-label="Close">
              <span aria-hidden="true">×</span>
            </button>
            <h4 className="modal-title">プランアップグレードの確認</h4>
          </div>
          <div className="modal-body">
            {!selectedPlan || !selectedPlan.key ? (
              <div className="text-center">
                <p>プラン情報が取得できませんでした</p>
              </div>
            ) : loading ? (
              <div className="text-center">
                <p>読み込み中...</p>
              </div>
            ) : previewData ? (
              <div className="upgrade-preview-content">
                <div className="upgrade-preview-section" style={{ marginBottom: '20px' }}>
                  <h5 style={{ fontWeight: 'bold', marginBottom: '10px' }}>今回お支払いいただく金額</h5>
                  <p className="charge-amount" style={{ fontSize: '24px', fontWeight: 'bold', color: '#333' }}>
                    {previewData.current_charge_amount}
                  </p>
                </div>
                {previewData.next_charge_date && (
                  <div className="upgrade-preview-section" style={{ marginBottom: '20px' }}>
                    <h5 style={{ fontWeight: 'bold', marginBottom: '10px' }}>次回お支払い日</h5>
                    <p style={{ fontSize: '16px' }}>{previewData.next_charge_date}</p>
                  </div>
                )}
                <div className="upgrade-preview-section">
                  <h5 style={{ fontWeight: 'bold', marginBottom: '10px' }}>次回以降のお支払い金額</h5>
                  <p className="charge-amount" style={{ fontSize: '20px', fontWeight: 'bold', color: '#333' }}>
                    {previewData.next_charge_amount}
                  </p>
                </div>
              </div>
            ) : (
              <div className="text-center">
                <p>情報の取得に失敗しました</p>
                <p style={{ fontSize: '12px', color: '#999', marginTop: '10px' }}>
                  ブラウザのコンソールを確認してください
                </p>
              </div>
            )}
          </div>
          <div className="modal-footer flex justify-center gap-4">
            <button
              type="button"
              className="block btn btn-tarco"
              style={{ margin: 0 }}
              onClick={handleCancel}
              data-dismiss="modal"
            >
              キャンセル
            </button>
            <button
              type="button"
              className="block btn btn-yellow"
              style={{ margin: 0 }}
              onClick={handleConfirm}
              disabled={loading || !previewData}
            >
              了承して支払いへ
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default UpgradeConfirmationModal;

