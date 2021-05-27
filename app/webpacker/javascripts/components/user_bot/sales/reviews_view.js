"use strict";

import React from "react";
import I18n from 'i18n-js/index.js.erb';

const ReviewsView = ({reviews}) => {
  if (!reviews) return <></>

  return (
    <div className="content">
      <h3 className="header centerize">
        {I18n.t('user_bot.dashboards.sales.form.review_content_header')}
      </h3>
      {reviews.map((review, index) => {
        return (
          <div className="flex my-4" key={`review-item-${index}`}>
            <div className={`flex w-full customer-profile ${index % 2 == 1 ? "flex-row-reverse" : ""}`}>
              <img className={`customer-picture ${index % 2 == 0 ? "mr-2-5" : "ml-2-5"}`} src={review.picture_url} />
              <div className="flex flex-col text-left">
                <p className="break-line-content ml-1">
                  {review.content}
                </p>
                <span className="ml-1 text-gray-500 text-right text-12px">{review.customer_name}<span className="text-10px">{I18n.t("common.mr")}</span></span>
              </div>
            </div>
          </div>
        )
      })}
    </div>
  )
}

export default ReviewsView
