"use strict"

import React from "react";

const LineCardPreview = ({title, desc, btn_text, picture_url}) => {
  return (
    <div className="dummy-line-card">
      {picture_url.length ? (
        <div className='picture'>
          <img src={picture_url} />
        </div>
      ) : <></>}
      <div className='content'>
        <h3>
          {title}
        </h3>
        <div className="desc">
          {desc}
        </div>
      </div>
      <div className='actions centerize'>
        <div className="btn line-button btn-extend with-wording only-word">
          {btn_text}
        </div>
      </div>
    </div>
  )
}

export default LineCardPreview;
