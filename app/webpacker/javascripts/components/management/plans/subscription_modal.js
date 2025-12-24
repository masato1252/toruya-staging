"use strict";

import React from "react";
import PlanCharge from "./charge";
import _ from "lodash";

class SubscriptionModal extends React.Component {
  renderContent = () => {
    const isReserved = this.props.isReservedForDowngrade;
    
    return (
      <div className="downgrade-area">
        <div className="modal-body">
          <div>
            {this.isSpecialDowngradeLevel() ? this.props.i18n.specialDowngradeContent : (this.props.i18n.downgradeDesc || this.props.i18n.downgrade.desc)}
          </div>
          <div className="downgrade-label">
            {this.props.i18n.downgradeLabel1 || this.props.i18n.downgrade.label1}
          </div>
          <div>
            {this.props.i18n.downgradeDesc1 || this.props.i18n.downgrade_desc1}
          </div>
          {/* <div className="downgrade-label">
            {this.props.i18n.downgradeLabel1 || this.props.i18n.downgrade.label1}
          </div> */}
          {/* <div>
            {this.props.i18n.downgradeDesc2 || this.props.i18n.downgrade_desc2}
          </div> */}
        </div>
        <div className="modal-footer flex justify-center">
          {isReserved ? (
            <>
              <div
                className={`block btn btn-tarco mr-2`}
                onClick={() => { $("#subscription-modal").modal("hide"); }}
              >
                予約したままにする
              </div>
              <div
                className={`block btn btn-yellow`}
                onClick={this.props.onCancelReservation}
              >
                予約をキャンセルする
              </div>
            </>
          ) : (
            <>
              <div
                className={`block btn btn-tarco mr-2`}
                onClick={() => { $("#subscription-modal").modal("hide"); }}
              >
                {this.props.i18n.downgradeCancelBtn || this.props.i18n.downgrade.cancel_btn}
              </div>
              <PlanCharge
                {...this.props}
                plan={this.props.selectedPlan}
                rank={this.props.rank}
                chargeImmediately={false}
                downgrade={true}
              />
            </>
          )}
        </div>
      </div>
    );
  };

  isSpecialDowngradeLevel = () => {
    return _.includes(this.props.specialDowngradeLevels, this.props.selectedPlan?.level)
  }

  render() {
    return (
      <div className="modal fade" id="subscription-modal" tabIndex="-1" role="dialog">
        <div className="modal-dialog" role="document">
          <div className="modal-content">
            <div className="modal-header">
              <button type="button" className="close" data-dismiss="modal" aria-label="Close">
                <span aria-hidden="true">×</span>
              </button>
              <h4 className="modal-title" id="myModalLabel">
                {this.isSpecialDowngradeLevel() ? (this.props.i18n.specialDowngradeTitle) : (this.props.i18n.downgradeTitle || this.props.i18n.downgrade.modal_title)}
              </h4>
            </div>
            {this.renderContent()}
          </div>
        </div>
      </div>
    );
  }
};

export default SubscriptionModal;
