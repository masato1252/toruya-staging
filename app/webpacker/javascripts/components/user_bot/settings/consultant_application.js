"use strict";

import React from "react";
import { useForm } from "react-hook-form";
import Routes from 'js-routes.js'

import { TopNavigationBar } from "shared/components"
import { CommonServices } from "components/user_bot/api"
import { responseHandler } from "libraries/helper";

const ConsultantApplicationForm = ({props}) => {
  const { register, handleSubmit, formState } = useForm();

  const onSubmit = async (data) => {
    let error, response;

    [error, response] = await CommonServices.create({
      url: Routes.create_application_lines_user_bot_settings_consultants_path({business_owner_id: props.business_owner_id}),
      data: data
    });

    responseHandler(error, response);
  }

  return (
    <div className="form with-top-bar bg-white">
      <TopNavigationBar
        leading={
          <a href={Routes.lines_user_bot_settings_consultants_path(props.business_owner_id)}>
            <i className="fa fa-angle-left fa-2x"></i>
          </a>
        }
        title={I18n.t("user_bot.dashboards.settings.consultants.list_page_title")}
      />
      <div class="field-header">{"登録申請フォーム"}</div>
      <div className="margin-around">
        <h4>招待したいサポートユーザーの主な業種</h4>
        {
          ["飲食業", "小売業", "美容業", "医療・福祉", "教育・学習支援", "住宅・不動産", "旅行・観光",
           "スポーツ・レジャー", "エンターテインメント・メディア", "IT・テクノロジー", "金融・保険", "製造業", "農林水産・鉱業"].map((name) => {
            return (
              <div className="p-1" key={name}>
                <label className="">
                  <input name="category" type="checkbox" value={name} ref={register()} />
                  <span className="mx-2">{name}</span>
                </label>
              </div>
            )
          })
        }
        Other: <input name="other_category" type="input" ref={register()} />
      </div>
      <hr />
      <div className="margin-around">
        <h4>サポートできる業務内容</h4>
        {
          ["導入支援：Toruya導入をサポートし、ニーズに合わせたカスタマイズを行う",
           "集客支援：デジタルマーケティングの専門知識を活用して、効果的な広告キャンペーンやプロモーションを展開",
           "運用サポート：日常的なToruya運用の支援や問題解決、改善提案"].map((name) => {
            return (
              <div className="p-1" key={name}>
                <label className="">
                  <input name="support" type="checkbox" value={name} ref={register()} />
                  <span className="mx-2">{name}</span>
                </label>
              </div>
            )
          })
        }
        Other: <input name="other_support" type="input" ref={register()} />
      </div>
      <div className="centerize action-block">
        <button type="button" className="btn btn-yellow" onClick={handleSubmit(onSubmit)} disabled={formState.isSubmitting}>
          {formState.isSubmitting ? (
            <i className="fa fa-spinner fa-spin fa-fw fa-2x" aria-hidden="true"></i>
          ) : (
            I18n.t("action.send")
          )}
        </button>
      </div>
    </div>
  )
}

export default ConsultantApplicationForm
