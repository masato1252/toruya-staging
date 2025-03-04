import React from "react";

const CompanyInfoView = ({ info, className = "company-info" }) => {
  if (!info) return <></>;

  return (
    <div className={className}>
      {info.name && <div><b>{info.name}</b></div>}
      {info.address && <div>{info.address}</div>}
      {info.phone_number && (
        <div>
          <i className="fa fa-phone mr-2"></i>
          <a href={`tel:${info.phone_number}`}>{info.phone_number}</a>
        </div>
      )}
      {info.email && (
        <div>
          <i className="fa fa-envelope mr-2"></i>
          {info.email}
        </div>
      )}
      {info.website && (
        <div>
          <i className="fa fa-globe mr-2"></i>
          <a href={info.website} target="_blank">{info.website}</a>
        </div>
      )}
    </div>
  );
};

export default CompanyInfoView;