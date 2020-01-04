"use strict";

import React from "react";

class PrintingModal extends React.Component {
  renderFilteredOutcomes = () => {
    return (
      <div id="searchPrint">
        <dl className="tableTTL">
          <dt className="status">&nbsp;</dt>
          <dt className="filterName">{this.props.printingHeaderFilterName}</dt>
          <dt className="type">{this.props.printingHeaderFileType}</dt>
          <dt className="create">{this.props.printingHeaderCreatedDate}</dt>
          <dt className="exparation">{this.props.printingHeaderExpiredDate}</dt>
          <dt className="function"></dt>
        </dl>
        <div id="files">
          {
            this.props.filtered_outcome_options.map(function(outcome) {
              return (
                <dl key={outcome.id}>
                  <dd className="status">
                    {outcome.state === "processing" ? (
                      <i className="fa fa-hourglass-half"></i>
                    ) : (
                      <i className="fa fa-print"></i>
                    )}
                  </dd>
                  <dd className="filterName">{outcome.name}</dd>
                  <dd className="type">{outcome.type}</dd>
                  <dd className="create">{outcome.createdDate}</dd>
                  <dd className="exparation">{outcome.expiredDate}</dd>
                  <dd className="function">
                    {outcome.fileUrl ? (
                      <a href={outcome.fileUrl} className="BTNtarco" target="_blank">{this.props.printBtn}</a>
                    ) : null}
                  </dd>
                </dl>
              )
            }.bind(this))
          }
        </div>
      </div>
    )
  };

  render() {
    return (
      <div className="modal fade" id="printing-files-modal" tabIndex="-1" role="dialog">
        <div className="modal-dialog" role="document">
          <div className="modal-content">
            <div className="modal-header">
              <button type="button" className="close" data-dismiss="modal" aria-label="Close">
                <span aria-hidden="true">×</span>
              </button>
              <h4 className="modal-title" id="myModalLabel">
                <i className="fa fa-database" aria-hidden="true"></i>{this.props.filesForPrintWording}
                </h4>
              </div>
              <div className="modal-body">
                {this.renderFilteredOutcomes()}
              </div>
              <div className="modal-footer">
                <dl>
                  <dd><a href="#" className="btn BTNtarco" data-dismiss="modal">{this.props.closeButton}</a></dd>
                </dl>
              </div>
            </div>
          </div>
        </div>
    );
  }
};

export default PrintingModal;
