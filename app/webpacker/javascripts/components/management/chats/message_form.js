"use strict";

import React, { useEffect, useState, useRef, useContext } from "react";
import moment from "moment-timezone";
import TextareaAutosize from 'react-autosize-textarea';

import { CommonServices } from "components/user_bot/api"
import { GlobalContext } from "context/chats/global_state";
import { SubmitButton } from "shared/components";
import I18n from 'i18n-js/index.js.erb';
import Routes from 'js-routes.js'
import ProcessingBar from "shared/processing_bar";
import { getMomentLocale } from "libraries/helper.js";

const MessageForm = ({ locale = 'ja' }) => {
  moment.locale(getMomentLocale(locale));
  const ref = useRef()
  const { selected_customer, selected_channel_id, reply_message, reply_images, reply_image_urls, ai_question, dispatch } = useContext(GlobalContext)
  const [schedule_at, setScheduleAt] = useState(null)
  const [processing, setProcessing] = useState(false)
  const [prompt, setPrompt] = useState(localStorage.getItem("prompt") || "Context information is below.\n ---------------------\n {context_str}\n ---------------------\n You are a helpful assistant to Toruya(トルヤ).\n Write answers as you are replying on Toruya's official LINE account where the user asking questions on Toruya's official LINE account.\n Use given context information and not prior knowledge.\n Do not repeat questions.\n Use the wording and terminology of the given context information as much as possible, rather than the sentence from the question.\n Add line breaks as you need to make reply readable.\n Use text format with proper line break to make it readable.\n Provide only the most relevant reference url in the answer.\nThe answer should always be base on the given context information, don't make up your own answer.\n If you find multiple questions at once, just reply 'AIが正しくお返事できるように、ご質問は１つずつ送信してください。'.\n Don't use 'トルヤ', 'toruya' or 'TORUYA' but 'Toruya'.\n Don't use 'ライン', 'line', or 'Line' but 'LINE'.\n Don't use 'ライン公式アカウント', 'line公式アカウント', or 'Line公式アカウント' but 'LINE公式アカウント'.\n The answer must be in the same language with question.\n answer the query.\nIf you don't know the answer, always reply in English with 'NO CONTEXT'.\n If query is not question, always reply in English with 'NOT QUESTION'.\n Query: {query_str}\n Answer:")

  const aiReply = async () => {
    setProcessing(true)
    const [error, resp] = await CommonServices.create({
      url: Routes.ai_reply_admin_chats_path({format: "json"}),
      data: { question: ai_question, prompt: prompt }
    })
    setProcessing(false)
    localStorage.setItem("prompt", prompt);

    if (error) {
      alert(error.response.data.error_message)
    }
    else {
      dispatch({
        type: "REPLY_MESSAGE",
        payload: {
          reply_message: resp.data["message"]
        }
      })
    }
  }

  const buildAiFaqSample = async () => {
    const [error, resp] = await CommonServices.create({
      url: Routes.build_by_faq_admin_ai_index_path({format: "json"}),
      data: { question: ai_question, answer: reply_message }
    })

    if (error) {
      alert(error.response.data.error_message)
    }
    else {
      toastr.success("AI Sample Submitted")
    }
  }

  const handleSubmit = async () => {
    if (!ref.current.value && reply_images.length < 1) return;

    const [error, response] = await CommonServices.create({
      url: Routes.admin_chats_path({format: "json"}),
      data: {
        customer_id: selected_customer.id, message: ref.current.value, schedule_at: schedule_at, image: reply_images[0]
      }
    })

    ref.current.value = null;

    if (response?.data?.redirect_to) {
      window.location.replace(response?.data?.redirect_to)
    }
  }

  useEffect(() => {
    if (reply_images.length < 1) return;

    const newImageUrls = [];
    reply_images.forEach(image => newImageUrls.push(URL.createObjectURL(image)));

    dispatch({
      type: "REPLY_IMAGE_URL_MESSAGE",
      payload: {
        reply_image_urls: newImageUrls
      }
    })
  }, [reply_images])

  if (!selected_customer.id) return <></>

  return (
    <div id="chat-form">
      <ProcessingBar processing={processing} processingMessage={I18n.t("admin.chat.ai_processing")} />
      <TextareaAutosize value={prompt} onChange={(e) => setPrompt(e.target.value) } className="w-full display-hidden" />
      {ai_question && (
        <>
          <label>AI Question</label>
          <TextareaAutosize
            value={ai_question}
            onChange={(e) =>
                dispatch({
                  type: "AI_QUESTION",
                  payload: {
                    ai_question: e.target.value
                  }
                })
            }
            className="w-full"
          />
          <button className="btn btn-orange" onClick={aiReply} >{I18n.t("admin.chat.build_ai_reply")}</button>
        </>
      )}
      <TextareaAutosize
        ref={ref}
        className="extend with-border"
        placeholder={I18n.t("admin.chat.reply_placeholder")}
        value={reply_message}
        onChange={(e) =>
          dispatch({
            type: "REPLY_MESSAGE",
            payload: {
              reply_message: e.target.value
            }
          })
        }
      />
      <div>
        <label className="flex flex-col">
          <i className='fas fa-image fa-2x'></i>
          <input
            type="file" accept="image/png, image/jpg, image/jpeg"
            onChange={(e) => {
              dispatch({
                type: "REPLY_IMAGE_MESSAGE",
                payload: {
                  reply_images: [...e.target.files]
                }
              })
            }}
          className="display-hidden" />
          {reply_image_urls.map(imageSrc => <img src={imageSrc} key={imageSrc} className="w-full h-full object-contain" />)}
        </label>
      </div>
      <div className="text-left">
        <div className="margin-around m10 mt-0">
          <label>
            <input
              type="radio" name="schedule_at"
              checked={schedule_at == null}
              onChange={
                () => setScheduleAt(null)
              }
            />
            {I18n.t("common.send_now_label")}
          </label>
        </div>
        <div className="margin-around m10">
          <label>
            <input
              type="radio" name="send_later"
              checked={schedule_at !== null}
              onChange={
                () => setScheduleAt(moment().format("YYYY-MM-DDTHH:mm"))
              }
            />
            <input
              type="datetime-local"
              value={schedule_at || moment().format("YYYY-MM-DDTHH:mm")}
              onClick={() => setScheduleAt(moment().format("YYYY-MM-DDTHH:mm"))}
              onChange={(e) => setScheduleAt(e.target.value) }
            />
          </label>
        </div>
      </div>
      <div className="form-group col-sm-2">
        <SubmitButton
          handleSubmit={handleSubmit}
          btnWord={schedule_at ? I18n.t("action.save_as_schedule") : I18n.t("action.send_now")}
        />
      </div>
    </div>
  )
}

export default MessageForm;
