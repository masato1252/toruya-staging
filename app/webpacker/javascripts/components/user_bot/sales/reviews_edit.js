import React from "react";
import ImageUploader from "react-images-upload";
import TextareaAutosize from 'react-autosize-textarea';

import I18n from 'i18n-js/index.js.erb';

const ReviewsEdit = ({reviews, handleReviewChange}) => {
  return (
    <div className="p10 margin-around border border-solid border-black rounded-md sales">
      <h3 className="header centerize break-line-content">
        {I18n.t('user_bot.dashboards.sales.form.review_content_header')}
      </h3>
      {reviews.map((review, index) => {
        return (
          <div className="flex my-4" key={`review-item-${index}`}>
            <div className={`flex w-full customer-profile ${index % 2 == 1 ? "flex-row-reverse" : ""}`}>
              <ImageUploader
                defaultImages={review?.picture_url?.length ? [review.picture_url] : []}
                withIcon={false}
                withPreview={true}
                withLabel={false}
                singleImage={true}
                buttonText={I18n.t("user_bot.dashboards.sales.form.customer_picture_requirement_tip")}
                onChange={(picture, pictureDataUrl) => {
                  handleReviewChange({
                    type: "SET_REVIEW",
                    payload: {
                      index: index,
                      value: {
                        picture_url: pictureDataUrl,
                        picture: picture[0]
                      }
                    }
                  })
                }}
                imgExtension={[".jpg", ".png", ".jpeg", ".gif"]}
                maxFileSize={5242880}
              />
              <div className={`flex flex-col w-full ${index % 2 == 0 ? "ml-2-5" : "mr-2-5"}`}>
                <TextareaAutosize
                  className="centerize with-border text-left my-4"
                  placeholder={I18n.t('user_bot.dashboards.sales.form.review_content_placeholder')}
                  rows={1}
                  value={review?.content || ""}
                  onChange={(event) => {
                    handleReviewChange({
                      type: "SET_REVIEW",
                      payload: {
                        index: index,
                        value: {
                          content: event.target.value
                        }
                      }
                    })
                  }}
                />
                <div className="flex items-center justify-end">
                  <input
                    type="text"
                    value={review?.customer_name || ""}
                    placeholder={I18n.t('user_bot.dashboards.sales.form.review_customer_name_placeholder')}
                    onChange={(event) => {
                      handleReviewChange({
                        type: "SET_REVIEW",
                        payload: {
                          index: index,
                          value: {
                            customer_name: event.target.value
                          }
                        }
                      })
                    }}
                  />
                  <span className="text-10px w-5">{I18n.t("common.mr")}</span>
                  <button className="btn btn-orange" onClick={() => handleReviewChange({ type: "REMOVE_REVIEW", payload: { index } }) }>
                    <i className="fa fa-minus"></i>
                  </button>
                </div>
              </div>
            </div>
          </div>
        )
      })}
      <div className="action-block">
        <button className="btn btn-yellow" onClick={() => handleReviewChange({ type: "ADD_REVIEW" }) }>
          {I18n.t('user_bot.dashboards.sales.form.add_review')}
        </button>
      </div>
    </div>
  )
}

export default ReviewsEdit
