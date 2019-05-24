"use strict";
import React from "react";

const ChargeFailedModal = (props) => {
  return (
    <div className="modal fade" id="charge-failed-modal" tabIndex="-1" role="dialog">
      <div className="modal-dialog" role="document">
        <div className="modal-content">
          <div className="modal-header">
            <button type="button" className="close" data-dismiss="modal" aria-label="Close">
              <span aria-hidden="true">×</span>
            </button>
            <h4 className="modal-title" id="myModalLabel">
              {props.i18n.chargeFailedTitle}
            </h4>
          </div>
          <div className="modal-body">
            {props.i18n.chargeFailedDesc1}
            <br />
            {props.i18n.chargeFailedDesc2}
          </div>
          <div className="modal-footer">
            <div
             className={`btn btn-tarco`}
             onClick={() => { $("#charge-failed-modal").modal("hide"); }}
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
