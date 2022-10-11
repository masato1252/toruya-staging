"use strict"

import React from "react";

const LineCardPreview = ({ picture_url, title, desc, actions }) => {
  return (
    <div className="dummy-line-card">
      {picture_url?.length ? (
        <div className='picture'>
          <img src={picture_url} />
        </div>
      ) : <></>}
      <div className='content'>
        {title && <h3>{title}</h3>}
        {desc && <div className="desc">{desc}</div>}
      </div>
      {actions && <div className='actions centerize'>{actions}</div>}
    </div>
  )
}

export default LineCardPreview;
